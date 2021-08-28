package org.xtext.gradle.test

import com.google.common.io.Files
import java.io.File

import static org.junit.Assert.assertEquals

class OutputSnapshot {
	val File baseDir
	new(File baseDir) {
		this.baseDir = baseDir
		Files.fileTraverser().depthFirstPreOrder(baseDir).forEach[
			it.lastModified = 0
		]
	}

	def assertChangedClasses(String... names) {
		val actual = Files.fileTraverser().depthFirstPreOrder(baseDir)
		.filter[ it.name.endsWith(".java") ]
		.filter[ it.lastModified != 0 ]
		.map [ it.name ]
		.toSet
		val expected = names.map[ it + ".java" ].toSet
		assertEquals(expected, actual)
	}
}