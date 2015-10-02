package org.xtext.gradle.test

import org.junit.Ignore
import org.junit.Test

import static org.hamcrest.core.IsEqual.equalTo
import static org.junit.Assert.*
import static org.junit.Assume.*

/**
 * Tests for Xtend projects that do not use the default configuration.
 */
class BuildingANonStandardXtendProject extends AbstractIntegrationTest {

	override setup() {
		super.setup()
		buildFile << xtendPluginSnippet
	}

	@Test
	def void compilesToJava8WhenConfigured() {
		assumeTrue(System.getProperty('java.version').startsWith('1.8'))

		// given 
		createXtendHelloWorld
		buildFile << '''
			xtext.languages.xtend.generator.javaSourceLevel = "1.8"
		'''

		// when
		build('generateXtext')

		// then
		val generatedJava = file('build/xtend/main/HelloWorld.java').contentAsString
		assertTrue(generatedJava.contains('import java.util.function.Consumer;'))
	}

	@Test @Ignore
	def void compilesToJava7WhenConfigured() {
		// given 
		createXtendHelloWorld
		buildFile << '''
			xtext.languages.xtend.generator.javaSourceLevel = "1.7"
		'''

		// when
		build('generateXtext')

		// then
		val generatedJava = file('build/xtend/main/HelloWorld.java').contentAsString
		assertFalse(generatedJava.contains('import java.util.function.Consumer;'))
	}

	@Test
	def void failsOnConstantBooleanExpressionWhenConfigured() {
		// given
		createFile('src/main/java/HelloWorld.xtend', '''
			class HelloWorld {
				
				def void helloWorld() {
					if (true) {
					}
				}
				
			}
		''')
		buildFile << '''
			xtext.languages.xtend.validator {
				error 'org.eclipse.xtext.xbase.validation.IssueCodes.constant_condition'
			}
		'''

		// when
		val result = buildAndFail('build')

		// then
		assertTrue(result.standardError.contains('Constant condition is always true'))
	}

}