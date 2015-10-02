package org.xtext.gradle.test

import org.junit.Ignore
import org.junit.Test
import org.xtext.gradle.tasks.XtextGenerate
import org.gradle.api.tasks.compile.JavaCompile

class WhenSettingsChange extends AbstractIntegrationTest {

	override setup() {
		super.setup
		buildFile << '''
			«xtendPluginSnippet»
			xtext {
				languages.xtend.generator.javaSourceLevel = "1.7"
			}
			tasks.withType(«XtextGenerate.name») {
				encoding = "UTF-8"
			}
			tasks.withType(«JavaCompile.name») {
				options.encoding = "UTF-8"
			}
		'''
		createXtendHelloWorld
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

	@Test @Ignore
	def void shouldRecompileWhenLanguageSettingsChange() {
		// when
		buildFile.content = buildFile.contentAsString.
			replace('''javaSourceLevel = "1.7"''', '''javaSourceLevel = "1.8"''')
		val result = build('build')

		// then
		result.xtextTask.shouldNotBeUpToDate
	}

}