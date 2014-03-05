package org.xtext.gradle;

import static org.codehaus.groovy.runtime.DefaultGroovyMethods.capitalize

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.BasePlugin;
import org.xtext.gradle.tasks.Language
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate

class XtextPlugin implements Plugin<Project> {

	def void apply(Project project) {
		project.plugins.apply(BasePlugin)
		project.configurations.create("xtext")
		def XtextExtension xtext = project.extensions.create("xtext", XtextExtension, project);
		xtext.languages.all{Language language ->
			def task = project.tasks.create("generate${language.name.capitalize()}") { 
				println("This is the Xtext plugin, generating for the ${language.name.capitalize()} language") 
			}
			project.tasks[BasePlugin.ASSEMBLE_TASK_NAME].dependsOn(task)
		}
	}
}
