package org.xtend.gradle.idea

import org.gradle.plugins.ide.eclipse.model.EclipseModel
import org.gradle.testfixtures.ProjectBuilder
import org.junit.Test
import org.xtext.gradle.idea.IdeaComponentPlugin

import static org.junit.Assert.*
import org.gradle.api.GradleException

class IdeaPluginTest {
	
	@Test
	def void shouldNotEvaluateGradleHomeTooEarly() {
		val project = ProjectBuilder.builder.build
		project.plugins.apply("org.xtext.idea-plugin")
		project.plugins.apply("eclipse")
	}
	
	@Test
	def void shouldAddIdeaDependenciesToEclipseClasspath() {
		val project = ProjectBuilder.builder.build
		project.plugins.apply("org.xtext.idea-plugin")
		
		project.plugins.apply("eclipse")
		
		val ideaProvided = project.configurations.getAt(IdeaComponentPlugin.IDEA_PROVIDED_CONFIGURATION_NAME)
		val eclipseConfigurations = project.convention.getByType(EclipseModel).classpath.plusConfigurations
		assertTrue(eclipseConfigurations.contains(ideaProvided))
	}
	
	@Test(expected = GradleException)
	def void shouldRefuseToAddComponentAndAggregatorPluginOnSameProject() {
		val project = ProjectBuilder.builder.build
		project.plugins.apply("org.xtext.idea-plugin")
		project.plugins.apply("org.xtext.idea-aggregator")
	}
}