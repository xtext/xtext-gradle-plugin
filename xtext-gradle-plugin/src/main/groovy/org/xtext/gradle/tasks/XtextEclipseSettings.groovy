package org.xtext.gradle.tasks;

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.TaskAction

class XtextEclipseSettings extends DefaultTask {

	private XtextExtension xtext

	def configure(XtextExtension xtext) {
		this.xtext = xtext
	}

	@TaskAction
	def writeSettings() {
		xtext.languages.each {Language language ->
			def prefs = new StringBuilder()
			prefs.append("autobuilding=true\n")
			prefs.append("eclipse.preferences.version=1\n")
			prefs.append("is_project_specific=true\n")

			language.outputs.each {OutputConfiguration output ->
				prefs.append("outlet.${output.name}.cleanDirectory=true\n")
				prefs.append("outlet.${output.name}.cleanupDerived=true\n")
				prefs.append("outlet.${output.name}.createDirectory=true\n")
				prefs.append("outlet.${output.name}.derived=true\n")
				prefs.append("outlet.${output.name}.directory=${output.dir}\n")
				prefs.append("outlet.${output.name}.hideLocalSyntheticVariables=true\n")
				prefs.append("outlet.${output.name}.installDslAsPrimarySource=false\n")
				prefs.append("outlet.${output.name}.keepLocalHistory=false\n")
				prefs.append("outlet.${output.name}.override=true\n")
			}
			project.file(".settings/${language.setup.replace('StandaloneSetup', '')}.prefs").write(prefs.toString())
		}
	}
}
