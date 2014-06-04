package org.xtext.gradle;

import javax.inject.Inject
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.plugins.BasePlugin
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.gradle.plugins.ide.eclipse.EclipsePlugin
import org.gradle.plugins.ide.eclipse.model.EclipseModel
import org.xtext.gradle.tasks.XtextEclipseSettings
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate

import static extension org.xtext.gradle.GradleExtensions.*

class XtextPlugin implements Plugin<Project> {

	FileResolver fileResolver

	@Inject
	new(FileResolver fileResolver) {
		this.fileResolver = fileResolver
	}

	private def String getPluginVersion() {
		this.class.package.implementationVersion
	}

	override void apply(Project project) {
		project.plugins.<BasePlugin>apply(BasePlugin)
		project.plugins.<EclipsePlugin>apply(EclipsePlugin)

		val xtext = project.extensions.create("xtext", XtextExtension, project, fileResolver);

		val xtextTooling = project.configurations.create("xtextTooling")
		val xtextDependencies = project.configurations.create("xtext")

		val settingsTask = project.tasks.create("xtextEclipseSettings", XtextEclipseSettings)
		settingsTask.configure(xtext)
		project.tasks.getAt(EclipsePlugin.ECLIPSE_TASK_NAME).dependsOn(settingsTask)

		val eclipse = project.extensions.getByType(EclipseModel)
		eclipse.project.buildCommand("org.eclipse.xtext.ui.shared.xtextBuilder")
		eclipse.project.natures("org.eclipse.xtext.ui.shared.xtextNature")

		val generatorTask = project.tasks.create("xtextGenerate", XtextGenerate)

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
			val java = project.convention.findPlugin(JavaPluginConvention)
			if (java != null) {
				java.sourceSets.forEach [ sourceSet |
					val sourceDirs = sourceSet.java.srcDirs
					val xtextOutputDirs = xtext.languages.map[outputs.map[project.file(dir)]].flatten
					sourceDirs.removeAll(xtextOutputDirs)
					xtext.sources.srcDirs(sourceDirs.toArray)
				]
				xtextDependencies.extendsFrom(project.configurations.getAt(JavaPlugin.TEST_COMPILE_CONFIGURATION_NAME))
				xtext.languages.forEach [ language |
					language.outputs.forEach [ output |
						if (output.javaSourceSet !== null) {
							project.dependencies.add("compile",
								'''org.eclipse.xtext:org.eclipse.xtext.xbase.lib:«xtext.version»''')
							output.javaSourceSet.java.srcDir(output.dir)
						}
					]
				]
				project.tasks.getAt(JavaPlugin.COMPILE_JAVA_TASK_NAME).dependsOn(generatorTask)
			}
			generatorTask.configure(xtext)
			generatorTask.xtextClasspath = xtextTooling
			generatorTask.classpath = xtextDependencies
			project.tasks.getAt(BasePlugin.ASSEMBLE_TASK_NAME).dependsOn(generatorTask)
		]
	}
}
