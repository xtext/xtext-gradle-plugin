package org.xtext.gradle

import org.gradle.api.plugins.JavaBasePlugin
import org.gradle.api.plugins.JavaPluginExtension
import org.junit.Test
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate

import static org.junit.Assert.*

class XtextBuilderPluginTest extends AbstractPluginTest {

	override getPluginClass() {
		XtextBuilderPlugin
	}

	@Test
	def void xtextExtensionIsAdded() {
		// when
		project.apply(pluginClass)

		// then	
		assertNotNull(project.extensions.getByType(XtextExtension))
	}

	@Test
	def void xtextLanguagesConfigurationIsAdded() {
		// when
		project.apply(pluginClass)

		// then
		assertNotNull(project.configurations.getByName('xtextLanguages'))
	}

	@Test
	def void generateXtextTaskIsAddedForEverySourceSet() {
		// given
		project.apply(JavaBasePlugin)
		val java = project.extensions.getByType(JavaPluginExtension)
		java.sourceSets => [
			create('main')
			create('custom')
			create('test')
		]

		// when
		project.apply(pluginClass)

		// then
		val taskNames = project.tasks.withType(XtextGenerate).names
		assertTrue(taskNames.contains('generateXtext'))
		assertTrue(taskNames.contains('generateCustomXtext'))
		assertTrue(taskNames.contains('generateTestXtext'))
	}

}