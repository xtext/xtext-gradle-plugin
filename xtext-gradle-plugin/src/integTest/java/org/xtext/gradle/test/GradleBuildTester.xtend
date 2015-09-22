package org.xtext.gradle.test

import com.google.common.base.Charsets
import com.google.common.collect.ImmutableMap
import com.google.common.hash.HashCode
import com.google.common.hash.Hashing
import com.google.common.io.Files
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.Map
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.gradle.tooling.GradleConnectionException
import org.gradle.tooling.GradleConnector
import org.gradle.tooling.ProjectConnection
import org.junit.rules.ExternalResource
import org.junit.rules.TemporaryFolder

import static org.junit.Assert.*
import java.util.Collections
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest

class GradleBuildTester extends ExternalResource {
	val temp = new TemporaryFolder
	ProjectUnderTest rootProject
	ProjectConnection gradle

	override protected before() throws Throwable {
		temp.create
		rootProject = new ProjectUnderTest => [
			name = "root"
			projectDir = temp.newFolder(name)
			owner = this
		]
		gradle = GradleConnector.newConnector
			.forProjectDirectory(rootProject.projectDir)
			.connect
	}
	
	override protected after() {
		gradle.close
		temp.delete
	}
	
	def ProjectUnderTest getRootProject() {
		rootProject
	}
	
	def BuildResult executeTasks(String... tasks) {
		val result = new BuildResult
		try {
			val out = new ByteArrayOutputStream
			val err = new ByteArrayOutputStream
			gradle.newBuild
				.setStandardOutput(out)
				.setStandardError(err)
				.forTasks(tasks)
				.run
			result.standardOut = new String(out.toByteArray, Charsets.UTF_8)
			result.standardErr = new String(err.toByteArray, Charsets.UTF_8)
		} catch (GradleConnectionException e) {
			result.failure = e
		}
		result
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
		
		def File file(String relativePath) {
			new File(projectDir, relativePath)
		}
		
		def File createFile(String relativePath, CharSequence content) {
			val file = file(relativePath)
			file.content = content
			file
		}
		
		def FileCollectionSnapshot snapshotBuildDir() {
			FileCollectionSnapshot.forFolder(file("build"))
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
			if (parent == null) {
				""
			} else {
				parent.path + ":" + name
			}
		}
	}
	
	@Accessors(PUBLIC_GETTER)
	static class BuildResult {
		Throwable failure
		String standardOut
		String standardErr
		
		def void shouldSucceed() {
			assertNull(failure)
		}
		
		def void shouldFail() {
			assertNotNull(failure)
		}
	}
	
}

@Data
class FileCollectionSnapshot {
	static def forFolder(File folder) {
		val files = Files.fileTreeTraverser.breadthFirstTraversal(folder).filter[isFile]
		forFiles(files)
	}

	static def forFiles(File... files) {
		val snapshots = files.toMap[it].mapValues [
			new FileSnapshot(it, Files.hash(it, Hashing.md5))
		]
		new FileCollectionSnapshot(ImmutableMap.copyOf(snapshots))
	}
	
	Map<File, FileSnapshot> files

	def FileCollectionDiff changesSince(FileCollectionSnapshot before) {
		val added = newHashSet
		val deleted = newHashSet
		val modified = newHashSet
		files.entrySet.forEach [
			val existingSnapshot = before.files.get(key)
			if (existingSnapshot == null) {
				added.add(value.file)
			} else if (existingSnapshot.checksum != value.checksum) {
				modified.add(value.file)
			}
		]
		deleted.addAll(before.files.keySet)
		deleted.removeAll(files.keySet)
		new FileCollectionDiff(added, deleted, modified)
	}
}

@Data
class FileSnapshot {
	File file
	HashCode checksum
}

@Data
class FileCollectionDiff {
	Set<File> added
	Set<File> deleted
	Set<File> modified

	def void shouldBeAdded(File file) {
		assertTrue(added.contains(file))
	}

	def void shouldBeDeleted(File file) {
		assertTrue(deleted.contains(file))
	}

	def void shouldBeModified(File file) {
		assertTrue(modified.contains(file))
	}

	def void shouldBeUnchanged(File file) {
		assertFalse(added.contains(file) || deleted.contains(file) || modified.contains(file))
	}

	def void shouldBeEmpty() {
		assertTrue(added.isEmpty)
		assertTrue(deleted.isEmpty)
		assertTrue(modified.isEmpty)
	}
}