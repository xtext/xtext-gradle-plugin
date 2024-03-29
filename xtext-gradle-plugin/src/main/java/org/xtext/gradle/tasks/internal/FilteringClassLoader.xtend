package org.xtext.gradle.tasks.internal

import java.util.List

/**
 * @author Christian Dietrich - Initial contribution and API
 */
class FilteringClassLoader extends ClassLoader {

	static val char DOT = '.'
	static val char SLASH = '/'

	val List<String> includes
	val List<String> resourceIncludes

	new(ClassLoader parent, List<String> includes) {
		super(parent)
		this.includes = includes.map[it + DOT].immutableCopy
		this.resourceIncludes = includes.map[replace(DOT, SLASH)].map[it + SLASH].immutableCopy
	}

	override loadClass(String name, boolean resolve) throws ClassNotFoundException {
		try {
			return ClassLoader.systemClassLoader.parent?.loadClass(name)
		} catch (ClassNotFoundException ignored) {
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
		for (it : includes) {
			if(name.startsWith(it)) return true;
		}
		false
	}

	private def isValidResource(String name) {
		for (it : resourceIncludes) {
			if(name.startsWith(it)) return true;
		}
		false
	}

}
