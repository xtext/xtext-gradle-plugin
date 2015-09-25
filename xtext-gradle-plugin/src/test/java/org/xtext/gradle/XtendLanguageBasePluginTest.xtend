package org.xtext.gradle

import org.gradle.api.plugins.JavaBasePlugin
import org.junit.Test
import org.xtext.gradle.tasks.XtextExtension

import static org.junit.Assert.*

class XtendLanguageBasePluginTest extends AbstractPluginTest {

	override getPluginClass() {
		XtendLanguageBasePlugin
	}

	@Test
	def void expectedPluginsAreAdded() {
		// when
		project.apply(pluginClass)

		// then
		assertTrue(project.plugins.hasPlugin(JavaBasePlugin))
		assertTrue(project.plugins.hasPlugin(XtextBuilderPlugin))
		assertTrue(project.plugins.hasPlugin(XtextJavaLanguagePlugin))
	}

	@Test
	def void xtendLanguageIsAdded() {
		// when
		project.apply(pluginClass)

		// then
		val ext = project.extensions.getByType(XtextExtension)
		val languageNames = ext.languages.names
		assertTrue(languageNames.contains('xtend'))
	}

}