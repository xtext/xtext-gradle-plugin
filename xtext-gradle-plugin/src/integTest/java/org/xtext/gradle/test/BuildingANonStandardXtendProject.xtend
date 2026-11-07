package org.xtext.gradle.test

import java.util.regex.Pattern
import org.junit.Test

import static org.junit.Assert.*

/**
 * Tests for Xtend projects that do not use the default configuration.
 */
class BuildingANonStandardXtendProject extends AbstractXtendIntegrationTest {

	@Test
	def void compilesToLambdaSourceWhenConfigured() {
		// given
		createHelloWorld
		buildFile << '''
			java {
				sourceCompatibility = JavaVersion.VERSION_21
			}
		'''

		// when
		build('generateXtext')

		// then
		val generatedJava = file('build/xtend/main/HelloWorld.java').contentAsString
		val lambda = Pattern.compile('''\(String \w+\) -> \{''')
		assertTrue(lambda.matcher(generatedJava).find)
	}

	@Test
	def void fallsBackToNearestSupportedJavaVersion() {
		// given: Xtext has no constant for Java 18, the nearest lower one is 17
		createHelloWorld
		buildFile << '''
			java {
				sourceCompatibility = JavaVersion.VERSION_18
			}
		'''

		// when
		val result = build('generateXtext')

		// then
		assertTrue(result.output.contains('''Java source level "18" is not supported by the Xtext version in use, generating code for Java "17" instead.'''))
		val generatedJava = file('build/xtend/main/HelloWorld.java').contentAsString
		val lambda = Pattern.compile('''\(String \w+\) -> \{''')
		assertTrue(lambda.matcher(generatedJava).find)
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