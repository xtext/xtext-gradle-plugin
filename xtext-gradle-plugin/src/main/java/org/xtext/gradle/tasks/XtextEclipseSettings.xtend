package org.xtext.gradle.tasks;

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.TaskAction

class XtextEclipseSettings extends DefaultTask {

	private XtextExtension xtext

	def configure(XtextExtension xtext) {
		this.xtext = xtext
	}

	@TaskAction
	def writeSettings() {
		xtext.languages.forEach [ Language language |
			val prefs = new XtextEclipsePreferences(project, language.name)
			prefs.load
			prefs.putBoolean("is_project_specific", true)
			language.outputs.forEach [ output |
				prefs.put(output.getKey("directory"), project.file(output.dir).absolutePath)
			]
			prefs.save
		]
	}

	def String getKey(OutputConfiguration output, String preferenceName) '''outlet.«output.name».«preferenceName»'''
}
