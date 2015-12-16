package org.xtext.gradle.tasks.internal

import java.util.List

class FilteringClassLoader extends ClassLoader {
	val List<String> includes

	new(ClassLoader parent, List<String> includes) {
		super(parent)
		this.includes = includes
	}

	override loadClass(String name, boolean resolve) throws ClassNotFoundException {
		try {
			return ClassLoader.systemClassLoader.parent?.loadClass(name)
		} catch(ClassNotFoundException ignored) {
		}
		
		if (name.isValidClass) {
			val result = super.loadClass(name, false)
			if (resolve) {
				resolveClass(result)
			}
			return result
		} else {
			throw new ClassNotFoundException(name)
		}
	}

	private def isValidClass(String name) {
		includes.exists[name.startsWith(it + ".")]
	}

}