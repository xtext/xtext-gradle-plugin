package org.xtext.gradle.tasks.internal

import java.util.Map
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.gradle.api.Project
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextSourceSetOutputs
import groovy.lang.MissingPropertyException

@FinalFieldsConstructor
class DefaultXtextSourceSetOutputs implements XtextSourceSetOutputs {
	val Project project
	val Map<Outlet, Object> dirs = newHashMap
	val Map<String, Outlet> outletsByPropertyName = newHashMap

	override getDirs() {
		project.files(dirs.values)
	}

	override getDir(Outlet outlet) {
		project.file(dirs.get(outlet))
	}

	override dir(Outlet outlet, Object path) {
		dirs.put(outlet, path)
	}
	
	def registerOutletPropertyName(String name, Outlet outlet) {
		outletsByPropertyName.put(name, outlet)
	}
	
	def propertyMissing(String name, Object value) {
		val outlet = outletsByPropertyName.get(name)
		if (outlet === null)
			throw new MissingPropertyException('''
				Unknown output directory '«name»'
				Known directories are:
				«FOR dir : outletsByPropertyName.keySet»
					«dir»
				«ENDFOR»
			''')
		dirs.put(outlet, value)
	}
}