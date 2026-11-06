package org.xtext.gradle;

import java.io.File
import java.util.LinkedHashSet
import java.util.Properties
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
import org.gradle.api.tasks.TaskProvider
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
		val generatorTask = project.tasks.register(sourceSet.generatorTaskName, XtextGenerate) [
			sources = sourceSet
			sourceSetOutputs = sourceSet.output
			languages = xtext.languages
			// captured at configuration time: Task.getProject() is an error in Gradle 10
			projectName.set(project.name)
			projectDirectory.set(project.projectDir)
			options.incremental.convention(true)
			options.encoding.convention("UTF-8")
		]
		setupXtextClasspath(sourceSet, generatorTask)
		project.tasks.register('clean' + sourceSet.generatorTaskName.toFirstUpper, Delete) [
				delete([
					xtext.languages.map[generator.outlets].flatten.filter[cleanAutomatically.get].map [
						sourceSet.output.getDir(it)
					].toSet
				] as Callable<Set<File>>)
			]
		]
	}

	private def setupXtextClasspath(XtextSourceDirectorySet sourceSet, TaskProvider<XtextGenerate> generatorTask) {
		val xtextTooling = project.configurations.create(sourceSet.qualifyConfigurationName("xtextTooling"))
		generatorTask.configure[
			xtextClasspath.from(xtextTooling)
		]
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
					output.dir(outlet, project.layout.buildDirectory.dir(language.name + outlet.folderFragment + '/' + sourceSet.name))
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
				val javaCompile = project.tasks.named(javaSourceSet.compileJavaTaskName, JavaCompile)
				xtext.sourceSets.maybeCreate(javaSourceSet.name) => [ xtextSourceSet |
					val generatorTask = project.tasks.named(xtextSourceSet.generatorTaskName, XtextGenerate)
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
					javaCompile.configure [ javaCompileTask |
						javaCompileTask.dependsOn(generatorTask)
						javaCompileTask.doLast(new Action<Task>() {
							override void execute(Task it) {
								generatorTask.get.installDebugInfo(javaCompileTask.destinationDirectory.get.asFile)
							}
						})
					]
					generatorTask.configure [
						options.encoding.set(project.provider[javaCompile.get.options.encoding ?: "UTF-8"])
						classpath.from(project.provider[javaSourceSet.compileClasspath])
					]
				]
			]
	]
	}

	private def integrateWithEclipsePlugin() {
		project.plugins.withType(EclipsePlugin) [
		val settingsTask = project.tasks.register("xtextEclipseSettings", XtextEclipseSettings) [
			languages = xtext.languages
			sourceSets = xtext.sourceSets
			projectDirectory.set(project.projectDir)
		]
			// Gradle 9 deprecates the eclipse*/cleanEclipse* file generation tasks and removes
			// them in Gradle 10. Eclipse Buildship imports the Gradle model itself, so only the
			// Xtext-specific .settings files still have to be written - and they do not need the
			// eclipse task to do it. Wire them into the regular lifecycle instead.
			//
			// Matched lazily rather than via named("classes"): this plugin only applies
			// 'base' and 'jvm-ecosystem', so a plain-language project that applies the
			// eclipse plugin has no 'classes' task and named() would fail configuration.
			project.tasks.matching [ Task task | task.name == "classes" ].configureEach [
				dependsOn(settingsTask)
			]

			val eclipse = project.extensions.getByType(EclipseModel)
			eclipse.project.buildCommand("org.eclipse.xtext.ui.shared.xtextBuilder")
			eclipse.project.natures("org.eclipse.xtext.ui.shared.xtextNature")
			eclipse.synchronizationTasks(settingsTask)
		]
	}

	private static class LazyXtextVersion {
		/**
		 * The floor this plugin release is built and tested against, baked into the jar
		 * at build time from the minimumXtextVersion Gradle property. Loaded lazily on
		 * first use so a packaging problem surfaces as a readable build failure instead
		 * of an ExceptionInInitializerError.
		 */
		static var String minimumVersion

		val XtextExtension xtext
		val Configuration languages
		val TaskProvider<XtextGenerate> task
		var String version

		new(XtextExtension xtext, Configuration languages, TaskProvider<XtextGenerate> task) {
			this.xtext = xtext
			this.languages = languages
			this.task = task
		}

		private static def String minimumXtextVersion() {
			if (minimumVersion === null) {
				val resource = "xtext-gradle-plugin.properties"
				val stream = typeof(LazyXtextVersion).classLoader.getResourceAsStream(resource)
				if (stream === null) {
					throw new GradleException('''Could not load "«resource»" from the classpath - the Xtext Gradle plugin appears to be packaged incorrectly.''')
				}
				try {
					val properties = new Properties
					properties.load(stream)
					minimumVersion = properties.getProperty("minimumXtextVersion")
				} finally {
					stream.close
				}
				if (minimumVersion === null) {
					throw new GradleException('''"«resource»" does not contain minimumXtextVersion - the Xtext Gradle plugin appears to be packaged incorrectly.''')
				}
			}
			return minimumVersion
		}

		def String getVersion() {
			if (version === null) {
				// Resolved here, at dependency-resolution time: realizing the task earlier
				// would defeat the lazy register() above.
				val realized = task.get
				version = xtext.getXtextVersion(realized.classpath) ?: xtext.getXtextVersion(languages)
				if (version === null && !realized.mainSources.empty) {
					throw new GradleException('''Could not infer Xtext classpath for «realized», because xtext.version was not set and no xtext libraries were found in «realized.classpath» or «languages»''')
				}
			}
		val minimumVersion = minimumXtextVersion()
		if (version !== null && new ComparableVersion(version) < new ComparableVersion(minimumVersion)) {
			throw new GradleException('''Xtext «version» is no longer supported. The minimum version is «minimumVersion»''')

		}
		version
	}
	}
}
