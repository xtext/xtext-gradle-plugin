package org.xtext.gradle.builder

import com.google.common.collect.Maps
import java.io.File
import java.io.IOException
import java.net.URLClassLoader
import java.util.concurrent.ConcurrentMap

//TODO remove as soon as present in Xtext nightly
class AlternateJdkLoader extends URLClassLoader {
	private final ConcurrentMap<String, Object> locks = Maps.newConcurrentMap;

	new(Iterable<File> files) {
		super(files.map[toURI.toURL])
	}

	override protected loadClass(String name, boolean resolve) throws ClassNotFoundException {
		synchronized (getClassLoadingLockJdk5(name)) {
			val c = findLoadedClass(name) ?: findClass(name)
			if (resolve) {
				resolveClass(c)
			}
			c
		}
	}

	override getResource(String name) {
		findResource(name)
	}

	override getResources(String name) throws IOException {
		findResources(name)
	}

	private def Object getClassLoadingLockJdk5(String className) {
		val newLock = new Object
		val existingLock = locks.putIfAbsent(className, newLock)
		return existingLock ?: newLock
	}
}
