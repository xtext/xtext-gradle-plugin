package org.xtext.gradle;

import java.io.File
import java.util.LinkedHashSet
import java.util.Set
import java.util.concurrent.Callable
import org.apache.maven.artifact.versioning.ComparableVersion
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.artifacts.Configuration
import org.gradle.api.plugins.JavaBasePlugin
import org.gradle.api.plugins.JavaPluginExtension
import org.gradle.api.tasks.Delete
import org.gradle.api.tasks.compile.JavaCompile
import org.gradle.plugins.ide.eclipse.EclipsePlugin
import org.gradle.plugins.ide.eclipse.model.EclipseModel
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextEclipseSettings
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate
import org.xtext.gradle.tasks.XtextSourceDirectorySet
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller

class XtextBuilderPlugin implements Plugin<Project> {

	Project project
	XtextExtension xtext
	Configuration xtextLanguages

	override void apply(Project project) {
		this.project = project

		project.plugins.apply("base")
		project.plugins.apply("jvm-ecosystem")

		xtext = project.extensions.create("xtext", XtextExtension);
		xtextLanguages = project.configurations.create("xtextLanguages")
		createGeneratorTasks
		configureDefaults
		integrateWithJavaPlugin
		integrateWithEclipsePlugin
	}

	private def createGeneratorTasks() {
		xtext.sourceSets.all [ sourceSet |
			val generatorTask = project.tasks.create(sourceSet.generatorTaskName, XtextGenerate) [
				sources = sourceSet
				sourceSetOutputs = sourceSet.output
				languages = xtext.languages
				options.incremental.convention(true)
				options.encoding.convention("UTF-8")
			]
			setupXtextClasspath(sourceSet, generatorTask)
			project.tasks.create('clean' + sourceSet.generatorTaskName.toFirstUpper, Delete) [
				delete([
					xtext.languages.map[generator.outlets].flatten.filter[cleanAutomatically.get].map [
						sourceSet.output.getDir(it)
					].toSet
				] as Callable<Set<File>>)
			]
		]
	}

	private def setupXtextClasspath(XtextSourceDirectorySet sourceSet, XtextGenerate generatorTask) {
		val xtextTooling = project.configurations.create(sourceSet.qualifyConfigurationName("xtextTooling"))
		generatorTask.xtextClasspath.from(xtextTooling)
		xtextTooling.extendsFrom(xtextLanguages)
		#[
			'org.eclipse.xtext:org.eclipse.xtext',
			'org.eclipse.xtext:org.eclipse.xtext.smap',
			'org.eclipse.xtext:org.eclipse.xtext.xbase',
			'org.eclipse.xtext:org.eclipse.xtext.java'
		].forEach [
			project.dependencies.add(xtextTooling.name, it)
		]
		project.dependencies.add(xtextTooling.name,
			project.dependencies.enforcedPlatform('''org.eclipse.xtext:xtext-dev-bom'''))

		val xtextVersion = new LazyXtextVersion(xtext, xtextLanguages, generatorTask)
		xtextTooling.resolutionStrategy.eachDependency [
			val version = xtextVersion.getVersion
			if (version === null) {
				return
			}
			if (requested.group == "org.eclipse.xtext" || requested.group == "org.eclipse.xtend") {
				useVersion(version)
			}
		]
	}

	private def configureDefaults() {
		xtext.languages.all [ language |
			language.fileExtensions.convention(project.provider[#{language.name}])
			language.qualifiedName.convention(language.setup.map[it.replace("StandaloneSetup", "")])
			language.generator.outlets.create(Outlet.DEFAULT_OUTLET)
			language.generator.suppressWarningsAnnotation.convention(true)
			language.generator.generatedAnnotation.active.convention(false)
			language.generator.generatedAnnotation.includeDate.convention(false)
			language.debugger.sourceInstaller.convention(SourceInstaller.NONE.name)
			language.debugger.hideSyntheticVariables.convention(true)
			language.generator.outlets.all [ outlet |
				outlet.producesJava.convention(false)
				outlet.cleanAutomatically.convention(true)
				xtext.sourceSets.all [ sourceSet |
					val output = sourceSet.output
					output.dir(outlet, '''«project.buildDir»/«language.name»«outlet.folderFragment»/«sourceSet.name»''')
				]
			]
		]
	}

	private def integrateWithJavaPlugin() {
		project.plugins.withType(JavaBasePlugin) [
			project.apply[plugin(XtextJavaLanguagePlugin)]
			val java = project.extensions.getByType(JavaPluginExtension)
			xtext.languages.all [
				generator.javaSourceLevel.convention(project.provider[java.sourceCompatibility.majorVersion])
			]
			java.sourceSets.all [ javaSourceSet |
				val javaCompile = project.tasks.getByName(javaSourceSet.compileJavaTaskName) as JavaCompile
				xtext.sourceSets.maybeCreate(javaSourceSet.name) => [ xtextSourceSet |
					val generatorTask = project.tasks.getByName(xtextSourceSet.generatorTaskName) as XtextGenerate
					xtextSourceSet.srcDirs([javaSourceSet.java.srcDirs] as Callable<Set<File>>)
					xtextSourceSet.srcDirs([javaSourceSet.resources.srcDirs] as Callable<Set<File>>)
					javaSourceSet.allSource.srcDirs([
						val dslSources = new LinkedHashSet(xtextSourceSet.srcDirs)
						dslSources.removeAll(javaSourceSet.java.srcDirs)
						dslSources.removeAll(javaSourceSet.resources.srcDirs)
						dslSources
					] as Callable<Set<File>>)
					javaSourceSet.java.srcDirs([
						val javaProducingOutlets = xtext.languages.map[generator.outlets].flatten.filter[producesJava.get]
						project.files(javaProducingOutlets.map[xtextSourceSet.output.getDir(it)]).builtBy(generatorTask)
					] as Callable<Iterable<File>>)
					javaCompile.dependsOn(generatorTask)
					javaCompile.doLast(new Action<Task>() {
						override void execute(Task it) {
							generatorTask.installDebugInfo(javaCompile.destinationDirectory.get.asFile)
						}
					})
					generatorTask.options.encoding.set(project.provider[javaCompile.options.encoding ?: "UTF-8"])
					generatorTask.classpath.from(project.provider[javaSourceSet.compileClasspath])
				]
			]
		]
	}

	private def integrateWithEclipsePlugin() {
		project.plugins.withType(EclipsePlugin) [
			val settingsTask = project.tasks.create("xtextEclipseSettings", XtextEclipseSettings)
			settingsTask.languages = xtext.languages
			settingsTask.sourceSets = xtext.sourceSets
			project.tasks.getAt(EclipsePlugin.ECLIPSE_TASK_NAME).dependsOn(settingsTask)
			project.tasks.getAt("cleanEclipse").dependsOn("cleanXtextEclipseSettings")

			val eclipse = project.extensions.getByType(EclipseModel)
			eclipse.project.buildCommand("org.eclipse.xtext.ui.shared.xtextBuilder")
			eclipse.project.natures("org.eclipse.xtext.ui.shared.xtextNature")
			eclipse.synchronizationTasks(settingsTask)
		]
	}

	private static class LazyXtextVersion {
		val XtextExtension xtext
		val Configuration languages
		val XtextGenerate task
		var String version

		new(XtextExtension xtext, Configuration languages, XtextGenerate task) {
			this.xtext = xtext
			this.languages = languages
			this.task = task
		}

		def String getVersion() {
			if (version === null) {
				version = xtext.getXtextVersion(task.classpath) ?: xtext.getXtextVersion(languages)
				if (version === null && !task.mainSources.empty) {
					throw new GradleException('''Could not infer Xtext classpath for «task», because xtext.version was not set and no xtext libraries were found in «task.classpath» or «languages»''')
				}
			}
			val minimumVersion = "2.17.1"
			if (version !== null && new ComparableVersion(version) < new ComparableVersion(minimumVersion)) {
				throw new GradleException('''Xtext «version» is no longer supported. The minimum version is «minimumVersion»''')

			}
			version
		}
	}
}
