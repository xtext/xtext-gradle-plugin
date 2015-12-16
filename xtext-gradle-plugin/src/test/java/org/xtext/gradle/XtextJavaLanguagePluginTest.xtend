package org.xtext.gradle

import org.junit.Test
import org.xtext.gradle.tasks.XtextExtension

import static org.junit.Assert.*

class XtextJavaLanguagePluginTest extends AbstractPluginTest {

	override getPluginClass() {
		XtextJavaLanguagePlugin
	}

	@Test
	def void expectedPluginsAreAdded() {
		// when
		project.apply(pluginClass)

		// then
		assertTrue(project.plugins.hasPlugin(XtextBuilderPlugin))
	}

	@Test
	def void javaLanguageIsAdded() {
		// when
		project.apply(pluginClass)

		// then
		val ext = project.extensions.getByType(XtextExtension)
		val languageNames = ext.languages.names
		assertTrue(languageNames.contains('java'))
	}

}