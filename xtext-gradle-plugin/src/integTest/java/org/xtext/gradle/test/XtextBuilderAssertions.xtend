package org.xtext.gradle.test

import org.gradle.testkit.runner.BuildResult
import java.io.File
import org.junit.Assert

class XtextBuilderAssertions {
	def void hasRunGeneratorFor(BuildResult buildResult, File file) {
		Assert.assertTrue(buildResult.containsGeneratorRunFor(file))
	}
	
	def void hasNotRunGeneratorFor(BuildResult buildResult, File file) {
		Assert.assertFalse(buildResult.containsGeneratorRunFor(file))
	}
	
	private def containsGeneratorRunFor(BuildResult buildResult, File file) {
		buildResult.standardOutput.contains("Starting validation for input: '" + file.name + "'")
	}
}