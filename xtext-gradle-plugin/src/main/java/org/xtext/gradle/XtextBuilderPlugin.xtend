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
import org.gradle.api.file.FileCollection
import org.gradle.api.internal.file.collections.LazilyInitializedFileCollection
import org.gradle.api.internal.plugins.DslObject
import org.gradle.api.internal.tasks.TaskDependencyResolveContext
import org.gradle.api.plugins.JavaBasePlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.gradle.api.tasks.Delete
import org.gradle.api.tasks.compile.JavaCompile
import org.gradle.plugins.ide.eclipse.EclipsePlugin
import org.gradle.plugins.ide.eclipse.model.EclipseModel
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextClasspathInferrer
import org.xtext.gradle.tasks.XtextEclipseSettings
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate
import org.xtext.gradle.tasks.XtextSourceDirectorySet

import static extension org.xtext.gradle.GradleExtensions.*

class XtextBuilderPlugin implements Plugin<Project> {

	Project project
	XtextExtension xtext
	Configuration xtextLanguages

	override void apply(Project project) {
		this.project = project

		project.plugins.apply("base")
		if (project.supportsJvmEcoSystemplugin) {
			project.plugins.apply("jvm-ecosystem")
		}

		xtext = project.extensions.create("xtext", XtextExtension, project);
		xtextLanguages = project.configurations.create("xtextLanguages")
		xtext.makeXtextCompatible(xtextLanguages)
		automaticallyInferXtextCoreClasspath
		createGeneratorTasks
		configureOutletDefaults
		integrateWithJavaPlugin
		integrateWithEclipsePlugin
	}

	private def createGeneratorTasks() {
		xtext.sourceSets.all [ sourceSet |
			project.tasks.create(sourceSet.generatorTaskName, XtextGenerate) [
				sources = sourceSet
				sourceSetOutputs = sourceSet.output
				languages = xtext.languages
				val XtextGenerate generate = it
				xtextClasspath = new LazilyInitializedFileCollection() {
					override getDisplayName() {
						"Xtext classpath"
					}

					override createDelegate() {
						inferXtextClasspath(sourceSet, generate.classpath)
					}

					override visitDependencies(TaskDependencyResolveContext context) {
						context.add(generate.classpath)
						context.add(xtextLanguages)
					}

				}
			]
			project.tasks.create('clean' + sourceSet.generatorTaskName.toFirstUpper, Delete) [
				delete([
					xtext.languages.map[generator.outlets].flatten.filter[cleanAutomatically].map [
						sourceSet.output.getDir(it)
					].toSet
				] as Callable<Set<File>>)
			]
		]
	}

	private def inferXtextClasspath(XtextSourceDirectorySet sourceSet, FileCollection classpath) {
		xtext.classpathInferrers.fold(xtextLanguages as FileCollection) [ newXextClasspath, inferrer |
			inferrer.inferXtextClasspath(sourceSet, newXextClasspath, classpath)
		]
	}

	private def automaticallyInferXtextCoreClasspath() {
		xtext.classpathInferrers += new XtextClasspathInferrer() {
			override inferXtextClasspath(XtextSourceDirectorySet sourceSet, FileCollection xtextClasspath, FileCollection classpath) {
				val version = xtext.getXtextVersion(classpath) ?: xtext.getXtextVersion(xtextClasspath)
				if (version === null) {
					throw new GradleException('''Could not infer Xtext classpath, because xtext.version was not set and no xtext libraries were found on the «classpath» classpath''')
				}
				val xtextTooling = project.configurations.create(sourceSet.qualifyConfigurationName("xtextTooling"))
				xtextTooling.dependencies += #[
					'org.eclipse.xtext:org.eclipse.xtext',
					'org.eclipse.xtext:org.eclipse.xtext.smap',
					'org.eclipse.xtext:org.eclipse.xtext.xbase',
					'org.eclipse.xtext:org.eclipse.xtext.java',
					'org.eclipse.jdt:org.eclipse.jdt.core:3.10.0'
				]
				.map[project.dependencies.create(it)]
				xtext.makeXtextCompatible(xtextTooling)
				xtext.forceXtextVersion(xtextTooling, version)
				xtextTooling.plus(xtextClasspath)
			}
		}
	}

	private def configureOutletDefaults() {
		xtext.languages.all [ language |
			language.generator.outlets.create(Outlet.DEFAULT_OUTLET)
			language.generator.outlets.all [ outlet |
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
			val java = project.convention.findPlugin(JavaPluginConvention)
			xtext.languages.all [
				new DslObject(generator).conventionMapping.map("javaSourceLevel")[java.sourceCompatibility.majorVersion]
			]
			java.sourceSets.all [ javaSourceSet |
				val javaCompile = project.tasks.getByName(javaSourceSet.compileJavaTaskName) as JavaCompile
				xtext.sourceSets.maybeCreate(javaSourceSet.name) => [ xtextSourceSet |
					val generatorTask = project.tasks.getByName(xtextSourceSet.generatorTaskName) as XtextGenerate
					xtextSourceSet.srcDirs([javaSourceSet.java.srcDirs] as Callable<Set<File>>)
					javaSourceSet.allSource.srcDirs([
						val dslSources = new LinkedHashSet(xtextSourceSet.srcDirs)
						dslSources.removeAll(javaSourceSet.java.srcDirs)
						dslSources
					] as Callable<Set<File>>)
					javaSourceSet.java.srcDirs([
						val javaProducingOutlets = xtext.languages.map[generator.outlets].flatten.filter[producesJava]
						project.files(javaProducingOutlets.map[xtextSourceSet.output.getDir(it)]).builtBy(generatorTask)
					] as Callable<Iterable<File>>)
					javaCompile.dependsOn(generatorTask)
					javaCompile.doLast(new Action<Task>() {
						override void execute(Task it) {
							generatorTask.installDebugInfo(javaCompile.destinationDir)
						}
					})
					new DslObject(generatorTask.options).conventionMapping.map("encoding")[javaCompile.options.encoding]
					new DslObject(generatorTask).conventionMapping.map("classpath")[javaSourceSet.compileClasspath]
					new DslObject(generatorTask).conventionMapping.map("bootstrapClasspath")[javaCompile.options.bootstrapClasspath]
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
			if (new ComparableVersion(project.gradle.gradleVersion) >= new ComparableVersion("5.4")) {
				eclipse.synchronizationTasks(settingsTask)
			}
		]
	}
}
