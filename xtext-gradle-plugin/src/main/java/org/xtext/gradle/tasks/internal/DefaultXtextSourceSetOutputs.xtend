package org.xtext.gradle.tasks.internal

import java.util.Map
import javax.inject.Inject
import org.gradle.api.internal.file.FileOperations
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextSourceSetOutputs

class DefaultXtextSourceSetOutputs implements XtextSourceSetOutputs {
	val FileOperations fileOperations
	val Map<Outlet, Object> dirs = newLinkedHashMap

	@Inject
	new(XtextExtension xtext, FileOperations fileOperations) {
		this.fileOperations = fileOperations
		xtext.languages.all [
			generator.outlets.whenObjectRemoved [
				dirs.remove(it)
			]
		]
	}

	override getDirs() {
		fileOperations.configurableFiles(dirs.values)
	}

	override getDir(Outlet outlet) {
		fileOperations.file(dirs.get(outlet))
	}

	override dir(Outlet outlet, Object path) {
		dirs.put(outlet, path)
	}
}
