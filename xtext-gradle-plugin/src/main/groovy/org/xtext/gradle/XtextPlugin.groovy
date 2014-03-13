package org.xtext.gradle;

import javax.inject.Inject

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.Configuration
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.plugins.BasePlugin
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.gradle.api.tasks.SourceSet
import org.gradle.plugins.ide.eclipse.EclipsePlugin;
import org.gradle.plugins.ide.eclipse.model.EclipseModel;
import org.xtext.gradle.tasks.Language
import org.xtext.gradle.tasks.OutputConfiguration;
import org.xtext.gradle.tasks.XtextEclipseSettings;
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate

class XtextPlugin implements Plugin<Project> {

	FileResolver fileResolver

	@Inject
	XtextPlugin(FileResolver fileResolver) {
		this.fileResolver = fileResolver
	}

	def void apply(Project project) {
		project.plugins.apply(BasePlugin)
		project.plugins.apply(EclipsePlugin)
		
		def XtextExtension xtext = project.extensions.create("xtext", XtextExtension, project, fileResolver);
		
		def Configuration xtextTooling = project.configurations.create("xtextTooling")
		def Configuration xtextDependencies = project.configurations.create("xtext")
		
		XtextEclipseSettings settingsTask = project.tasks.create("xtextEclipseSettings", XtextEclipseSettings)
		settingsTask.configure(xtext)
		project.tasks[EclipsePlugin.ECLIPSE_TASK_NAME].dependsOn(settingsTask)
		
		def EclipseModel eclipse = project.extensions.getByType(EclipseModel)
		eclipse.getProject().buildCommand("org.eclipse.xtext.ui.shared.xtextBuilder")
		eclipse.getProject().natures("org.eclipse.xtext.ui.shared.xtextNature")
		
		project.afterEvaluate{
			project.dependencies.add("xtextTooling", "org.eclipse.xtext:org.eclipse.xtext:${xtext.version}")
			project.dependencies.add("xtextTooling", "org.xtext:xtext-gradle-lib:0.0.2")

			def XtextGenerate generatorTask = project.tasks.create("xtextGenerate", XtextGenerate)
			def JavaPluginConvention java = project.convention.findPlugin(JavaPluginConvention)
			if (java != null) {
				java.sourceSets.each {SourceSet sourceSet ->
					def sourceDirs = sourceSet.getJava().getSrcDirs()
					def xtextOutputDirs = xtext.languages.collect{it.outputs.collect{project.file(it.dir)}}.flatten()
					sourceDirs.removeAll(xtextOutputDirs)
					xtext.sources.srcDirs(sourceDirs.toArray())
				}
				xtextDependencies.extendsFrom(project.configurations[JavaPlugin.TEST_COMPILE_CONFIGURATION_NAME])
				xtext.languages.each { Language language ->
					language.outputs.each { OutputConfiguration output ->
						if (output.javaSourceSet != null) {
							project.dependencies.add("compile", "org.eclipse.xtext:org.eclipse.xtext.xbase.lib:${xtext.version}")
							output.javaSourceSet.getJava().srcDir(output.dir)
						}
					}
				}
				project.tasks[JavaPlugin.COMPILE_JAVA_TASK_NAME].dependsOn(generatorTask)
			}
			generatorTask.configure(xtext)
			generatorTask.xtextClasspath = xtextTooling
			generatorTask.classpath = xtextDependencies

			project.tasks[BasePlugin.ASSEMBLE_TASK_NAME].dependsOn(generatorTask)
			
		}
	}
}
