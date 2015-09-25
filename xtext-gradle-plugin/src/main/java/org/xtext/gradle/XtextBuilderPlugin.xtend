package org.xtext.gradle;

import com.google.common.base.CaseFormat
import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.Configuration
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.plugins.BasePlugin
import org.gradle.api.plugins.JavaBasePlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.gradle.api.tasks.compile.JavaCompile
import org.gradle.plugins.ide.eclipse.EclipsePlugin
import org.gradle.plugins.ide.eclipse.model.EclipseModel
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextEclipseSettings
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate
import org.xtext.gradle.tasks.internal.DefaultXtextSourceSetOutputs

import static extension org.xtext.gradle.GradleExtensions.*

class XtextBuilderPlugin implements Plugin<Project> {

	val FileResolver fileResolver

	Project project
	XtextExtension xtext
	Configuration xtextTooling

	@Inject @FinalFieldsConstructor new() {
	}

	override void apply(Project project) {
		this.project = project

		project.plugins.<BasePlugin>apply(BasePlugin)
		xtext = project.extensions.create("xtext", XtextExtension, project, fileResolver);
		xtextTooling = project.configurations.create("xtextTooling") [
			exclude(#{'group' -> 'asm'})
		]
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
				xtextClasspath = xtextTooling
				enhanceBuilderDependencies
			]
		]
	}
	
	def void enhanceBuilderDependencies(XtextGenerate generatorTask) {
		generatorTask.beforeExecute[
			val builderClasspathBefore = generatorTask.xtextClasspath
			val classpath = generatorTask.classpath
			val version = xtext.getXtextVersion(classpath) ?: xtext.getXtextVersion(builderClasspathBefore)
			if (version === null) {
				throw new GradleException('''Could not infer Xtext classpath, because xtext.version was not set and no xtext libraries were found on the «classpath» classpath''')
			}
			val dependencies = #[
				project.dependencies.externalModule('''org.eclipse.xtext:org.eclipse.xtext:«version»''') [
					force = true
					exclude(#{'group' -> 'asm'})
				],
				project.dependencies.externalModule('''org.xtext:xtext-gradle-builder:«pluginVersion»''') [
					force = true
					exclude(#{'group' -> 'asm'})
				],
				project.dependencies.externalModule('com.google.inject:guice:4.0')[
					force = true
				]
			]
			generatorTask.xtextClasspath = project.configurations.detachedConfiguration(dependencies).plus(builderClasspathBefore)
		]
	}
	
	private def String getPluginVersion() {
		this.class.package.implementationVersion
	}

	private def configureOutletDefaults() {
		xtext.languages.all [ language |
			language.generator.outlets.create(Outlet.DEFAULT_OUTLET)
			language.generator.outlets.all [ outlet |
				xtext.sourceSets.all [ sourceSet |
					val outletFragment = if (outlet.name == Outlet.DEFAULT_OUTLET) {
							""
						} else {
							CaseFormat.LOWER_UNDERSCORE.to(CaseFormat.UPPER_CAMEL, outlet.name)
						}
					val output = sourceSet.output as DefaultXtextSourceSetOutputs
					output.dir(outlet, '''«project.buildDir»/«language.name»«outletFragment»/«sourceSet.name»''')
					output.registerOutletPropertyName(language.name + outletFragment + "Dir", outlet)
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
			val java = project.convention.findPlugin(JavaPluginConvention)
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
							javaCompile.doLast[
								generatorTask.installDebugInfo
							]
						}
						generatorTask.classpath = generatorTask.classpath ?: javaSourceSet.compileClasspath
						generatorTask.bootClasspath = generatorTask.bootClasspath ?: javaCompile.options.bootClasspath
						generatorTask.classesDir = generatorTask.classesDir ?: javaSourceSet.output.classesDir
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

			val eclipse = project.extensions.getByType(EclipseModel)
			eclipse.project.buildCommand("org.eclipse.xtext.ui.shared.xtextBuilder")
			eclipse.project.natures("org.eclipse.xtext.ui.shared.xtextNature")
		]
	}
}
