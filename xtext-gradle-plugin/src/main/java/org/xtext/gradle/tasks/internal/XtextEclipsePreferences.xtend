package org.xtext.gradle.tasks.internal

import java.io.File
import org.eclipse.core.internal.preferences.EclipsePreferences
import org.eclipse.core.runtime.Path
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.osgi.service.prefs.BackingStoreException

@FinalFieldsConstructor
class XtextEclipsePreferences extends EclipsePreferences {

	val File projectDir
	val String language

	override getLocation() {
		val path = new Path(projectDir.absolutePath)
		computeLocation(path, language)
	}

	override save() throws BackingStoreException {
		super.save
	}

	override load() throws BackingStoreException {
		super.load
	}
}
