package org.xtext.gradle.test

import org.junit.Test
import org.xtext.gradle.tasks.internal.Version

class WhenUsingXtendForTestsOnly extends AbstractXtendIntegrationTest {

	override getImplementationScope() {
		if (gradleVersion > Version.parse('5')) 'testImplementation' else 'testCompile'
	}

	@Test
	def theGeneratorShouldRunOnValidInput() {
		file('src/main/java/HelloWorld.java').content = '''
			public class HelloWorld {}
		'''

		file('src/test/java/HelloWorldTest.xtend').content = '''
			class HelloWorldTest {
				val HelloWorld = new HelloWorld
			}
		'''

		build("build")

		file('build/xtend/test/HelloWorldTest.java').shouldExist
		file('build/xtend/test/.HelloWorldTest.java._trace').shouldExist
	}
}
