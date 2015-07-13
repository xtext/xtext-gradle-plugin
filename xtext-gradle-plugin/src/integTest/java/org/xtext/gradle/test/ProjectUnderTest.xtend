package org.xtext.gradle.test

import com.google.common.base.Charsets
import com.google.common.collect.ImmutableMap
import com.google.common.hash.HashCode
import com.google.common.hash.Hashing
import com.google.common.io.Files
import java.io.File
import java.util.Map
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.gradle.tooling.GradleConnectionException
import org.gradle.tooling.GradleConnector
import org.gradle.tooling.ProjectConnection
import static org.junit.Assert.*
import org.junit.rules.ExternalResource
import org.junit.rules.TemporaryFolder

@FinalFieldsConstructor
class ProjectUnderTest extends ExternalResource {
	val temp = new TemporaryFolder
	@Accessors val String projectName
	ProjectConnection gradle

	new() {
		this("root")
	}
	
	override protected before() throws Throwable {
		temp.create
		temp.newFolder(projectName)
		gradle = GradleConnector.newConnector
			.forProjectDirectory(rootDir)
			.connect
	}
	
	override protected after() {
		gradle.close
		temp.delete
	}
	
	def File getRootDir() {
		new File(temp.root, projectName)
	}
	
	def void setBuildFile(CharSequence content) {
		new File(rootDir, 'build.gradle').content = content
	}
	
	def File file(String relativePath) {
		new File(rootDir, relativePath)
	}
	
	def File createFile(String relativePath, CharSequence content) {
		val file = file(relativePath)
		file.content = content
		file
	}
	
	def void setContent(File file, CharSequence content) {
		file.parentFile.mkdirs
		file.createNewFile
		Files.write(content, file, Charsets.UTF_8)
	}
	
	def String getContentAsString(File file) {
		Files.toString(file, Charsets.UTF_8)
	}
	
	def void shouldExist(File file) {
		assertTrue(file.exists)
	}
	
	def void shouldContain(File file, CharSequence content) {
		assertEquals(content.toString, file.contentAsString)
	}
	
	def FileCollectionSnapshot snapshot() {
		FileCollectionSnapshot.forFolder(file("build"))
	}
	
	def BuildResult executeTasks(String... tasks) {
		val result = new BuildResult
		try {
			gradle.newBuild.setStandardError(System.err).setStandardOutput(System.out).forTasks(tasks).run
		} catch (GradleConnectionException e) {
			result.failure = e
		}
		result
	}
	
	@Accessors(PUBLIC_GETTER)
	static class BuildResult {
		Throwable failure
		
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
			new FileSnapshot(it, Files.hash(it, Hashing.md5), lastModified)
		]
		new FileCollectionSnapshot(ImmutableMap.copyOf(snapshots))
	}
	
	Map<File, FileSnapshot> files

	def FileCollectionDiff diff(FileCollectionSnapshot before) {
		val added = newHashSet
		val deleted = newHashSet
		val modified = newHashSet
		val touched = newHashSet
		files.entrySet.forEach [
			val existingSnapshot = before.files.get(key)
			if (existingSnapshot == null) {
				added.add(value.file)
			} else if (existingSnapshot.checksum != value.checksum) {
				modified.add(value.file)
			} else if (existingSnapshot.lastModified != value.lastModified) {
				touched.add(value.file)
			}
		]
		deleted.addAll(before.files.keySet)
		deleted.removeAll(files.keySet)
		new FileCollectionDiff(added, deleted, modified, touched)
	}
}

@Data
class FileSnapshot {
	File file
	HashCode checksum
	long lastModified
}

@Data
class FileCollectionDiff {
	Set<File> added
	Set<File> deleted
	Set<File> modified
	Set<File> touched

	def void shouldBeAdded(File file) {
		assertTrue(added.contains(file))
	}

	def void shouldBeDeleted(File file) {
		assertTrue(deleted.contains(file))
	}

	def void shouldBeModified(File file) {
		assertTrue(modified.contains(file))
	}

	def void shouldBeTouched(File file) {
		assertTrue(touched.contains(file))
	}

	def void shouldBeUnchanged(File file) {
		assertFalse(added.contains(file) || deleted.contains(file) || modified.contains(file))
	}

	def void shouldBeUntouched(File file) {
		shouldBeUnchanged(file)
		assertFalse(touched.contains(file))
	}
}