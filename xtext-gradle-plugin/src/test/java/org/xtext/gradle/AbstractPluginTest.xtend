package org.xtext.gradle

import java.io.File
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.testfixtures.ProjectBuilder
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.gradle.api.Task

/**
 * Abstract base class for all plugin unit tests.
 * Contains some basic tests that every plugin should suffice.
 */
abstract class AbstractPluginTest {

	@Rule public val temporaryFolder = new TemporaryFolder()

	protected Project project
	protected File projectDir

	abstract def Class<? extends Plugin<?>> getPluginClass()

	/** 
	 * Setup the root project.
	 */
	@Before
	def void setupProject() {
		projectDir = temporaryFolder.root
		project = ProjectBuilder.builder.withProjectDir(projectDir).build
	}

	/**
	 * Helper method for creating new subprojects.
	 */
	protected def Project createSubproject(Project parentProject, String name) {
		return ProjectBuilder.builder.withName(name).withProjectDir(new File(projectDir, name)).withParent(
			parentProject).build
	}

	protected def void apply(Project project, Class<? extends Plugin<?>> pluginClass) {
		project.apply[plugin(pluginClass)]
	}
	
	protected def void task(Project project, Class<? extends Task> taskClass, String taskName) {
		project.task(#{'type' -> taskClass}, taskName)	
	}

	/**
	 * No exception is thrown if plugin is applied to a project.
	 */
	@Test
	def void noExceptionOnApply() {
		// when
		project.apply(pluginClass)
	}

	/**
	 * No exception is thrown if plugin is applied twice to a project.
	 */
	@Test
	def void applyIsIdempotent() {
		// when
		project.apply(pluginClass)
		project.apply(pluginClass)
	}

	/**
	 * No expection is thrown if plugin is applied to a subproject.
	 */
	@Test
	def void applyOnSingleSubproject() {
		// given
		val subproject = project.createSubproject('subproject')

		// when
		subproject.apply(pluginClass)
	}

	/**
	 * No exception is thrown if plugin is applied to the root project and multiple
	 * subprojects.
	 */
	@Test
	def void applyOnRootAndMultipleSubprojects() {
		// given
		val subprojects = #['a', 'b', 'c'].map[project.createSubproject(it)]

		// when
		project.apply(pluginClass)
		subprojects.forEach[apply(pluginClass)]
	}

}