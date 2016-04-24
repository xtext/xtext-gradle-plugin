package org.xtext.gradle.test

import java.util.regex.Pattern
import org.junit.Test

import static org.junit.Assert.*

/**
 * Tests for Xtend projects that do not use the default configuration.
 */
class BuildingANonStandardXtendProject extends AbstractXtendIntegrationTest {

	@Test
	def void compilesToJava8SourceWhenConfigured() {
		// given 
		createHelloWorld
		buildFile << '''
			sourceCompatibility = "1.8"
		'''

		// when
		build('generateXtext')

		// then
		val generatedJava = file('build/xtend/main/HelloWorld.java').contentAsString
		val lambda = Pattern.compile('''\(String \w+\) -> \{''')
		assertTrue(lambda.matcher(generatedJava).find)
	}

	@Test
	def void compilesToJava7SourceWhenConfigured() {
		// given 
		createHelloWorld
		buildFile << '''
			sourceCompatibility = "1.7"
		'''

		// when
		build('generateXtext')

		// then
		val generatedJava = file('build/xtend/main/HelloWorld.java').contentAsString
		val anonymousInnerClass = Pattern.compile('''new \w*<String>\(\) \{''')
		assertTrue(anonymousInnerClass.matcher(generatedJava).find)
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
		assertTrue(result.output.contains('Constant condition is always true'))
	}

}