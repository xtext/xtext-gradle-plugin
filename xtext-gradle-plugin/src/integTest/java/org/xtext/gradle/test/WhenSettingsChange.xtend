package org.xtext.gradle.test

import java.util.List
import org.apache.maven.artifact.versioning.ComparableVersion
import org.gradle.api.tasks.compile.JavaCompile
import org.junit.Test

class WhenSettingsChange extends AbstractXtendIntegrationTest {

	/**
	 * Two distinct source levels that the Xtext version under test actually supports.
	 * Xtext gained JAVA25 in 2.43, so the newer matrix exercises 21 -> 25 while the
	 * older one falls back to 17 -> 21 (21 being its highest supported level).
	 */
	protected def List<String> getSourceLevels() {
		xtextVersion.compareTo(new ComparableVersion("2.43")) >= 0 ? #["21", "25"] : #["17", "21"]
	}

	override setup() {
		super.setup
		buildFile << '''
			xtext {
				languages.xtend.generator.javaSourceLevel = "«sourceLevels.head»"
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
			replace('''javaSourceLevel = "«sourceLevels.head»"''', '''javaSourceLevel = "«sourceLevels.last»"''')
		val result = build('build')

		// then
		result.xtextTask.shouldNotBeUpToDate
	}

}