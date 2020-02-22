package org.xtext.gradle;

import java.io.File
import java.util.Set
import java.util.concurrent.Callable
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.gradle.api.Action
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.artifacts.Configuration
import org.gradle.api.file.FileCollection
import org.gradle.api.plugins.BasePlugin
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

import static org.xtext.gradle.XtextBuilderPluginVersion.*

import static extension org.xtext.gradle.GradleExtensions.*

class XtextBuilderPlugin implements Plugin<Project> {

	Project project
	XtextExtension xtext
	Configuration xtextLanguages

	override void apply(Project project) {
		this.project = project

		project.plugins.<BasePlugin>apply(BasePlugin)
		xtext = project.extensions.create("xtext", XtextExtension, project);
		xtextLanguages = project.configurations.create("xtextLanguages")
		xtext.makeXtextCompatible(xtextLanguages)
		automaticallyInferXtextCoreClasspath
		createGeneratorTasks
		configureOutletDefaults
		addSourceSetIncludes
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
				xtextClasspath = project.files(new Callable<FileCollection>() {
					FileCollection inferredClasspath
					override call() throws Exception {
						if (inferredClasspath === null) {
							inferredClasspath = inferXtextClasspath(sourceSet, generate.classpath)
						}
						inferredClasspath
					}
				})
			]
			project.tasks.create('clean' + sourceSet.generatorTaskName.toFirstUpper, Delete) [
				delete( [
					xtext.languages
						.map[generator.outlets].flatten
						.filter[cleanAutomatically]
						.map[sourceSet.output.getDir(it)]
						.toSet
				] as Callable<Set<File>>)
			]
		]
	}

	private def inferXtextClasspath(XtextSourceDirectorySet sourceSet, FileCollection classpath) {
		xtext.classpathInferrers.fold(xtextLanguages as FileCollection)[newXextClasspath, inferrer | inferrer.inferXtextClasspath(sourceSet, newXextClasspath, classpath) ]
	}
	
	
	private def automaticallyInferXtextCoreClasspath() {
		xtext.classpathInferrers += new XtextClasspathInferrer() {
			override inferXtextClasspath(XtextSourceDirectorySet sourceSet, FileCollection xtextClasspath, FileCollection classpath) {
				val xtextBuilder =  project.dependencies.externalModule('''org.xtext:xtext-gradle-builder:«PLUGIN_VERSION»''')
				val xtextTooling = project.configurations.create(sourceSet.qualifyConfigurationName("xtextTooling"))
				xtextTooling.dependencies += xtextBuilder
				xtext.makeXtextCompatible(xtextTooling)
				xtext.forceXtextVersion(xtextTooling, new Function0<String>() {
					String version = null
		
					override apply() {
						if (version === null) {
							version = xtext.getXtextVersion(classpath) ?: xtext.getXtextVersion(xtextClasspath)
							if (version === null) {
								throw new GradleException('''Could not infer Xtext classpath, because xtext.version was not set and no xtext libraries were found on the «classpath» classpath''')
							}
						}
						version
					}
				})
				val result = xtextTooling.plus(xtextClasspath)
				return result
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

	private def addSourceSetIncludes() {
		project.afterEvaluate [
			xtext.languages.all [lang|
				xtext.sourceSets.all[
					filter.include("**/*." + lang.fileExtension)
				]
			]
		]
	}

	private def integrateWithJavaPlugin() {
		project.plugins.withType(JavaBasePlugin) [
			project.apply[plugin(XtextJavaLanguagePlugin)]
			val java = project.convention.findPlugin(JavaPluginConvention)
			xtext.languages.all [
				project.afterEvaluate [p |
					generator.javaSourceLevel = generator.javaSourceLevel ?: java.sourceCompatibility.majorVersion
				]
			]
			java.sourceSets.all [ javaSourceSet |
				val javaCompile = project.tasks.getByName(javaSourceSet.compileJavaTaskName) as JavaCompile
				xtext.sourceSets.maybeCreate(javaSourceSet.name) => [ xtextSourceSet |
					val generatorTask = project.tasks.getByName(xtextSourceSet.generatorTaskName) as XtextGenerate
					project.afterEvaluate [ p |
						xtextSourceSet.srcDirs.forEach[
							javaSourceSet.allSource.srcDir(it)
						]
						javaSourceSet.java.srcDirs.forEach[
							xtextSourceSet.srcDir(it)
						]
						javaSourceSet.resources.srcDirs.forEach[
							xtextSourceSet.srcDir(it)
						]
						val javaOutlets = xtext.languages.map[generator.outlets].flatten.filter[producesJava]
						javaOutlets.forEach[
							javaSourceSet.java.srcDir(xtextSourceSet.output.getDir(it))
						]
						if (!javaOutlets.isEmpty) {
							javaCompile.dependsOn(generatorTask)
							javaCompile.doLast(new Action<Task>() {
								override void execute(Task it) {
									generatorTask.installDebugInfo(javaCompile.destinationDir)
								}
							})
						}
						generatorTask.options.encoding = generatorTask.options.encoding ?: javaCompile.options.encoding
						generatorTask.classpath = generatorTask.classpath ?: javaSourceSet.compileClasspath
						generatorTask.bootstrapClasspath = generatorTask.bootstrapClasspath ?: javaCompile.options.bootstrapClasspath
					]
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
		]
	}
}
