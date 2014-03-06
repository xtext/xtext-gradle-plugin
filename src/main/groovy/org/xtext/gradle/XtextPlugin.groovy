package org.xtext.gradle;

import javax.inject.Inject;

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.plugins.BasePlugin
import org.gradle.api.plugins.JavaPlugin;
import org.gradle.api.plugins.JavaPluginConvention;
import org.gradle.api.tasks.SourceSet;
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
		def XtextExtension xtext = project.extensions.create("xtext", XtextExtension, project, fileResolver);
		project.configurations.create("xtext")
		project.afterEvaluate{
			def XtextGenerate generatorTask = project.tasks.create("xtextGenerate", XtextGenerate)
			def java = project.convention.findPlugin(JavaPluginConvention)
			def needJava = xtext.languages.any {it.consumesJava}
			if (needJava && java != null) {
				xtext.sources.source(java.sourceSets.main.java)
			}
			generatorTask.configure(xtext)
			project.tasks[BasePlugin.ASSEMBLE_TASK_NAME].dependsOn(generatorTask)
			project.dependencies.add("xtext", "org.eclipse.xtext:org.eclipse.xtext:${xtext.version}")
		}
	}
}
