package org.xtext.gradle.test

import com.google.common.base.Charsets
import com.google.common.io.Files
import java.io.File
import java.util.Collections
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.testkit.runner.BuildResult
import org.gradle.testkit.runner.GradleRunner
import org.junit.rules.ExternalResource
import org.junit.rules.TemporaryFolder

import static org.junit.Assert.*

class GradleBuildTester extends ExternalResource {
	val temp = new TemporaryFolder
	ProjectUnderTest rootProject
	GradleRunner gradle

	override protected before() throws Throwable {
		temp.create
		rootProject = new ProjectUnderTest => [
			name = "root"
			projectDir = temp.newFolder(name)
			owner = this
		]
		gradle = GradleRunner.create.withProjectDir(rootProject.projectDir)
	}

	override protected after() {
		temp.delete
	}

	def ProjectUnderTest getRootProject() {
		rootProject
	}

	def BuildResult build(String... tasks) {
		gradle.withArguments(tasks).build
	}

	def BuildResult buildAndFail(String... tasks) {
		gradle.withArguments(tasks).buildAndFail
	}

	def void setContent(File file, CharSequence content) {
		file.parentFile.mkdirs
		file.createNewFile
		Files.write(content, file, Charsets.UTF_8)
	}

	def void append(File file, CharSequence content) {
		if (file.exists) {
			file.content = file.contentAsString + content
		} else {
			file.content = content
		}
	}

	def void << (File file, CharSequence content) {
		file.append(content)
	}

	def String getContentAsString(File file) {
		Files.toString(file, Charsets.UTF_8)
	}

	def byte[] getContent(File file) {
		Files.toByteArray(file)
	}

	def void shouldExist(File file) {
		assertTrue(file.exists)
	}

	def void shouldContain(File file, CharSequence content) {
		assertEquals(content.toString, file.contentAsString)
	}

	private def addSubProjectToBuild(ProjectUnderTest project) {
		val settingsFile = rootProject.file("settings.gradle")
		settingsFile.append("\ninclude '" + project.path + "'")
	}

	@Accessors(PUBLIC_GETTER)
	static class ProjectUnderTest {
		extension GradleBuildTester owner
		ProjectUnderTest parent
		String name
		File projectDir
		val subProjects = <ProjectUnderTest>newLinkedHashSet

		def void setBuildFile(CharSequence content) {
			new File(projectDir, 'build.gradle').content = content
		}

		def File getBuildFile() {
			new File(projectDir, 'build.gradle')
		}

		def File file(String relativePath) {
			new File(projectDir, relativePath)
		}

		def File createFile(String relativePath, CharSequence content) {
			val file = file(relativePath)
			file.content = content
			file
		}

		def ProjectUnderTest createSubProject(String name) {
			val newProject = new ProjectUnderTest
			newProject.name = name
			newProject.projectDir = file(name)
			newProject.parent = this
			newProject.owner = owner
			subProjects += newProject
			owner.addSubProjectToBuild(newProject)
			newProject
		}

		def Set<ProjectUnderTest> getSubProjects() {
			Collections.unmodifiableSet(subProjects)
		}

		def String getPath() {
			if (parent === null) {
				""
			} else {
				parent.path + ":" + name
			}
		}
	}
}
