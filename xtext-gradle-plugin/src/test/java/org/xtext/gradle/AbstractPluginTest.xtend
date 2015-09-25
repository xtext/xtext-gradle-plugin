package org.xtext.gradle

import java.io.File
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.testfixtures.ProjectBuilder
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

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

	@Test
	def void shouldNotThrowExceptionIfApplied() {
		// when
		project.apply(pluginClass)
	}

	@Test
	def void shouldNotThrowExceptionIfAppliedTwice() {
		// when
		project.apply(pluginClass)
		project.apply(pluginClass)
	}

	@Test
	def void canBeAppliedOnSubproject() {
		// given
		val subproject = project.createSubproject('subproject')

		// when
		subproject.apply(pluginClass)
	}

	@Test
	def void canBeAppliedOnRootAndMultipleSubprojects() {
		// given
		val subprojects = #['a', 'b', 'c'].map[project.createSubproject(it)]

		// when
		project.apply(pluginClass)
		subprojects.forEach[apply(pluginClass)]
	}

}