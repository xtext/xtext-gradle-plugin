package org.xtext.gradle

import org.gradle.api.plugins.JavaPlugin
import org.junit.Test
import org.xtext.gradle.tasks.XtextGenerate

import static org.junit.Assert.*

class XtendLanguagePluginTest extends AbstractPluginTest {

	override getPluginClass() {
		XtendLanguagePlugin
	}

	@Test
	def void expectedPluginsAreAdded() {
		// when
		project.apply(pluginClass)

		// then
		assertTrue(project.plugins.hasPlugin(JavaPlugin))
		assertTrue(project.plugins.hasPlugin(XtendLanguageBasePlugin))
	}
	
	@Test
	def void generateXtextTasksAreAvailable() {
		// when
		project.apply(pluginClass)
		
		// then
		val taskNames = project.tasks.withType(XtextGenerate).names
		assertTrue(taskNames.contains('generateXtext'))
		assertTrue(taskNames.contains('generateTestXtext'))
	}

}