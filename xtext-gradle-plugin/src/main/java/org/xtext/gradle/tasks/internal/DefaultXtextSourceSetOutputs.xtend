package org.xtext.gradle.tasks.internal

import java.util.Map
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.gradle.api.Project
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextSourceSetOutputs

@FinalFieldsConstructor
class DefaultXtextSourceSetOutputs implements XtextSourceSetOutputs {
	val Project project
	val Map<Outlet, Object> dirs = newHashMap

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