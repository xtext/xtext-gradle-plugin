package org.xtext.gradle.test

import org.junit.Test

class WhenUsingXtendForTestsOnly extends AbstractXtendIntegrationTest {

	override protected getXtendScope() {
		'testCompile'
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
