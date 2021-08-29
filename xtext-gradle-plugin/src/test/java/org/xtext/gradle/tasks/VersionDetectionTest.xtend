package org.xtext.gradle.tasks

import java.io.File
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import org.junit.runners.Parameterized.Parameter
import org.junit.runners.Parameterized.Parameters

import static org.junit.Assert.assertEquals

@RunWith(Parameterized)
class VersionDetectionTest {

	@Parameters(name="{0} -> {1}")
	static def String[][] versions() {
		#[
			#["guava-24.0.jar", null],
			#["org.eclipse.xtext.testlang-1.0.jar", null],
			#["org.eclipse.xtext-2.9.0.jar", "2.9.0"],
			#["org.eclipse.xtext.xbase.lib-v2.25.0-1234.jar", "v2.25.0-1234"],
			#["org.eclipse.xtext.xbase.lib.slim-2.26.0-SNAPSHOT.jar", "2.26.0-SNAPSHOT"],
			#["org.eclipse.xtext.xbase.lib.gwt-2.26.0.M1.jar", "2.26.0.M1"]
		]
	}

	@Parameter(0)
	public String jar

	@Parameter(1)
	public String version

	@Test
	def void versionIsExtractedCorrectly() {
		assertEquals(version, XtextExtension.getXtextVersion(new File(jar)))
	}
}
