package org.xtext.gradle.idea.tasks

import java.io.File
import java.net.URL
import java.nio.file.Files
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.gradle.api.DefaultTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*
import java.util.Date

@Accessors
class DownloadIdea extends DefaultTask {
	@OutputDirectory File ideaHome
	@Input @Optional String ideaVersion

	new() {
		onlyIf[ideaVersion !== null && needsRedownload(new IdeaDistribution(ideaVersion))]
	}

	@TaskAction
	def download() {
		val buildInfo = new IdeaDistribution(ideaVersion)
		project.delete(ideaHome)
		usingTmpDir[ tmp |
			val archiveFile = new File(tmp, buildInfo.archiveName)
			Files.copy(new URL(buildInfo.archiveUrl).openStream, archiveFile.toPath)
			project.copy [
				into(ideaHome)
				from(project.zipTree(archiveFile))
				includeEmptyDirs = false
			]
		]
		val sourceArchiveFile = new File(ideaHome, buildInfo.sourceArchiveName)
		Files.copy(new URL(buildInfo.sourceArchiveUrl).openStream, sourceArchiveFile.toPath)
		lastDownloaded = new Date
	}
	
	private def lastDownloadedFile() {
		ideaHome / '.lastDownloaded'
	}
	
	private def getLastDownloaded() {
		lastDownloadedFile.lastModified
	}
	
	private def setLastDownloaded(Date lastModified) {
		val file = lastDownloadedFile
		file.createNewFile
		file.lastModified = lastModified.time
	}
	
	private def needsRedownload(IdeaDistribution distribution) {
		project.gradle.startParameter.isRefreshDependencies || lastDownloaded == 0 || distribution.isSnapshot && lastDownloaded < new Date().time - 1000 * 60 * 60 * 24
	}
}

@Data class IdeaDistribution {
	String version
	
	def String getRepository() {
		if (isSnapshot) "snapshots" else "releases"
	}
	
	def boolean isSnapshot() {
		version.endsWith("-SNAPSHOT")
	}
	
	def String getContentBaseUrl() {
		'''https://www.jetbrains.com/intellij-repository/«repository»/com/jetbrains/intellij/idea/ideaIC/«version»'''
	}
	
	def String getArchiveName() {
		'''ideaIC-«version».zip'''
	}

	def String getArchiveUrl() {
		'''«contentBaseUrl»/«archiveName»'''
	}
	
	def String getSourceArchiveName() {
		'''ideaIC-«version»-sources.jar'''
	}

	def String getSourceArchiveUrl() {
		'''«contentBaseUrl»/«sourceArchiveName»'''
	}
}