package org.xtext.gradle;

import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.plugins.BasePlugin
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.gradle.api.tasks.compile.JavaCompile
import org.gradle.plugins.ide.eclipse.EclipsePlugin
import org.gradle.plugins.ide.eclipse.model.EclipseModel
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate

import static extension org.xtext.gradle.GradleExtensions.*
import org.gradle.internal.reflect.Instantiator

class XtextPlugin implements Plugin<Project> {

	val FileResolver fileResolver
	val Instantiator instantiator

	@Inject @FinalFieldsConstructor
	new() {}

	private def String getPluginVersion() {
		this.class.package.implementationVersion
	}

	override void apply(Project project) {
		project.plugins.<BasePlugin>apply(BasePlugin)
		project.plugins.<EclipsePlugin>apply(EclipsePlugin)

		val xtext = project.extensions.create("xtext", XtextExtension, project, fileResolver, instantiator);
		val xtextTooling = project.configurations.create("xtextTooling")

//		val settingsTask = project.tasks.create("xtextEclipseSettings", XtextEclipseSettings)
//		settingsTask.languages = xtext.languages
//		settingsTask.sourceSetOutputs = xtext.sourceSets.head.output
//		project.tasks.getAt(EclipsePlugin.ECLIPSE_TASK_NAME).dependsOn(settingsTask)

		val eclipse = project.extensions.getByType(EclipseModel)
		eclipse.project.buildCommand("org.eclipse.xtext.ui.shared.xtextBuilder")
		eclipse.project.natures("org.eclipse.xtext.ui.shared.xtextNature")
		
		xtext.sourceSets.all[sourceSet|
			project.tasks.create(sourceSet.generatorTaskName, XtextGenerate) => [
				sources = sourceSet
				sourceSetOutputs = sourceSet.output
				languages = xtext.languages
				xtextClasspath = xtextTooling
			]
		]
		
		project.plugins.withType(JavaPlugin) [
			val java = project.convention.findPlugin(JavaPluginConvention)
			xtext.parseJava = true
			java.sourceSets.all [ javaSourceSet |
				val javaCompile = project.tasks.getByName(javaSourceSet.compileJavaTaskName) as JavaCompile
				xtext.sourceSets.maybeCreate(javaSourceSet.name) => [
					val generatorTask = project.tasks.getByName(generatorTaskName) as XtextGenerate
					source(javaSourceSet.java)
					project.afterEvaluate[p|
						output.flatten.filter[producesJava].forEach[
							javaSourceSet.java.srcDir(dir)
							javaCompile.dependsOn(generatorTask)
						]
						generatorTask.classpath = javaSourceSet.compileClasspath
						generatorTask.bootClasspath = javaCompile.options.bootClasspath
					]
				]
			]
		]

		project.afterEvaluate [
			project.dependencies => [
				add(
					"xtextTooling",
					externalModule('''org.eclipse.xtext:org.eclipse.xtext.builder.standalone:«xtext.version»''') [
						force = true
						exclude(#{'group' -> 'asm'})
					]
				)
				add("xtextTooling", '''org.xtext:xtext-gradle-lib:«pluginVersion»''')
				add("xtextTooling", 'com.google.inject:guice:4.0-beta4')
			]
		]
	}
}
