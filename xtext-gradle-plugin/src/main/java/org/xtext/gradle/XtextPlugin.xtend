package org.xtext.gradle;

import com.google.common.base.CaseFormat
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
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate
import org.xtext.gradle.tasks.internal.DefaultXtextSourceSetOutputs

import static extension org.xtext.gradle.GradleExtensions.*

class XtextPlugin implements Plugin<Project> {

	val FileResolver fileResolver

	@Inject @FinalFieldsConstructor
	new() {}

	private def String getPluginVersion() {
		this.class.package.implementationVersion
	}

	override void apply(Project project) {
		project.plugins.<BasePlugin>apply(BasePlugin)
		project.plugins.<EclipsePlugin>apply(EclipsePlugin)

		val xtext = project.extensions.create("xtext", XtextExtension, project, fileResolver);
		val xtextTooling = project.configurations.create("xtextTooling")

//		val settingsTask = project.tasks.create("xtextEclipseSettings", XtextEclipseSettings)
//		settingsTask.languages = xtext.languages
//		settingsTask.sourceSetOutputs = xtext.sourceSets.head.output
//		project.tasks.getAt(EclipsePlugin.ECLIPSE_TASK_NAME).dependsOn(settingsTask)

		val eclipse = project.extensions.getByType(EclipseModel)
		eclipse.project.buildCommand("org.eclipse.xtext.ui.shared.xtextBuilder")
		eclipse.project.natures("org.eclipse.xtext.ui.shared.xtextNature")
		
		xtext.languages.all[language|
			language.outlets.create(Outlet.DEFAULT_OUTLET)
			language.outlets.all[outlet|
				xtext.sourceSets.all[sourceSet|
					val outletFragment = if (outlet.name == Outlet.DEFAULT_OUTLET) {
						""
					} else {
						CaseFormat.LOWER_UNDERSCORE.to(CaseFormat.UPPER_CAMEL, outlet.name)
					}
					val output =sourceSet.output as DefaultXtextSourceSetOutputs 
					output.dir(outlet, '''«project.buildDir»/«language.name»«outletFragment»/«sourceSet.name»''')
					output.registerOutletPropertyName(language.name + outletFragment + "OutputDir", outlet)
				]
			]
		]
		
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
						xtext.languages.forEach [ lang |
							lang.outlets.forEach [ outlet |
								if (outlet.producesJava) {
									javaSourceSet.java.srcDir(output.getDir(outlet))
									javaCompile.dependsOn(generatorTask)
								}
							]
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
