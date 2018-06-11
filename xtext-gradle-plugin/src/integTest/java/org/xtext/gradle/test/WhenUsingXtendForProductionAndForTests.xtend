package org.xtext.gradle.test

import org.junit.Test

class WhenUsingXtendForProductionAndForTests extends AbstractXtendIntegrationTest {

	@Test
	def buildShouldCreateFilesInOutputFoldersAsDefinedbySourceSets() {
		file('src/main/java/HelloWorld.xtend').content = '''
			public class HelloWorld {}
		'''

		file('src/test/java/HelloWorldTest.xtend').content = '''
			class HelloWorldTest {
				val HelloWorld = new HelloWorld
			}
		'''

		build("build")

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/classes/java/main/HelloWorld.class').shouldExist
		file('build/xtend/test/HelloWorldTest.java').shouldExist
		file('build/classes/java/test/HelloWorldTest.class').shouldExist
	}
}
