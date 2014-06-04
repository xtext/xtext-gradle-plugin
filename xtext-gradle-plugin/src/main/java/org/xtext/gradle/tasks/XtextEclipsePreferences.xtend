package org.xtext.gradle.tasks

import org.eclipse.core.internal.preferences.EclipsePreferences
import org.eclipse.core.runtime.Path
import org.gradle.api.Project
import org.osgi.service.prefs.BackingStoreException

class XtextEclipsePreferences extends EclipsePreferences {

	Project project
	String language

	new(Project project, String language) {
		this.project = project
		this.language = language
	}

	override protected getLocation() {
		val path = new Path(project.projectDir.absolutePath)
		computeLocation(path, language)
	}

	override public save() throws BackingStoreException {
		super.save
	}
	
	override public load() throws BackingStoreException {
		super.load
	}

}
