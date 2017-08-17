package org.xtext.gradle.tasks.internal

import java.util.List

class FilteringClassLoader extends ClassLoader {
	
	static val char DOT = '.'
	static val char SLASH = '/'
	
	val List<String> includes
	val List<String> resourceIncludes

	new(ClassLoader parent, List<String> includes) {
		super(parent)
		this.includes = includes
		this.resourceIncludes = includes.map[replace(DOT,SLASH)]
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

	override getResource(String name) {
		val result = ClassLoader.systemClassLoader.parent?.getResource(name)
		if (result !== null) {
			return result
		}
		if (name.isValidResource) {
			return super.getResource(name)
		}
		return null
	}

	private def isValidClass(String name) {
		includes.exists[name.startsWith(it + DOT)]
	}
	
	private def isValidResource(String name) {
		resourceIncludes.exists[name.startsWith(it + SLASH)]
	}

}