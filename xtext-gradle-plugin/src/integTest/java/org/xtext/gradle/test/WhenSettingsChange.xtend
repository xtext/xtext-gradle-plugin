package org.xtext.gradle.test

import org.gradle.api.tasks.compile.JavaCompile
import org.junit.Test

class WhenSettingsChange extends AbstractXtendIntegrationTest {

	override setup() {
		super.setup
		buildFile << '''
			xtext {
				languages.xtend.generator.javaSourceLevel = "1.7"
			}
			tasks.withType(«JavaCompile.name») {
				options.encoding = "UTF-8"
			}
		'''
		createHelloWorld
		build('build').xtextTask.shouldNotBeUpToDate
		build('build').xtextTask.shouldBeUpToDate
	}

	@Test
	def void shouldRecompileWhenEncodingChanges() {
		// when
		buildFile.content = buildFile.contentAsString.replace('''encoding = "UTF-8"''', '''encoding = "ISO-8859-1"''')
		val result = build('build')

		// then
		result.xtextTask.shouldNotBeUpToDate
	}

	@Test
	def void shouldRecompileWhenLanguageSettingsChange() {
		// when
		buildFile.content = buildFile.contentAsString.
			replace('''javaSourceLevel = "1.7"''', '''javaSourceLevel = "1.8"''')
		val result = build('build')

		// then
		result.xtextTask.shouldNotBeUpToDate
	}

}