package org.xtext.gradle.tasks.internal

import java.util.Map
import org.gradle.api.Project
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextSourceSetOutputs

class DefaultXtextSourceSetOutputs implements XtextSourceSetOutputs {
	val Project project
	val Map<Outlet, Object> dirs = newLinkedHashMap
	
	new(Project project, XtextExtension xtext) {
		this.project = project
		xtext.languages.all[
			generator.outlets.whenObjectRemoved[
				dirs.remove(it)
			]
		]
	}

	override getDirs() {
		project.files(dirs.values)
	}

	override getDir(Outlet outlet) {
		project.file(dirs.get(outlet))
	}

	override dir(Outlet outlet, Object path) {
		dirs.put(outlet, path)
	}
}
