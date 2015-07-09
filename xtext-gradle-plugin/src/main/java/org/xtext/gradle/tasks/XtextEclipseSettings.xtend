package org.xtext.gradle.tasks;

import com.google.common.base.CharMatcher
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.tasks.TaskAction

class XtextEclipseSettings extends DefaultTask {

	@Accessors Set<XtextSourceSet> sourceSets
	@Accessors Set<Language> languages

	@TaskAction
	def writeSettings() {
		languages.forEach [ Language language |
			val prefs = new XtextEclipsePreferences(project, language.qualifiedName)
			prefs.load
			//TODO Write all the settings!
			prefs.putBoolean("is_project_specific", true)
			sourceSets.forEach[
				language.outlets.forEach[outlet|
					prefs.put(outlet.getOutletKey("directory"), project.relativePath(output.getDir(outlet)).trimTrailingSeparator)
				]
			]
			prefs.save
		]
	}

	def String getOutletKey(Outlet output, String preferenceName) '''outlet.«output.name».«preferenceName»'''
	
	private def trimTrailingSeparator(String path) {
		CharMatcher.anyOf("/\\").trimTrailingFrom(path)
	}
}
