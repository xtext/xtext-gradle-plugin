package org.xtext.gradle.idea.tasks

import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Project
import org.gradle.api.file.FileCollection
import java.io.File
import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*

@Accessors
class IdeaExtension {
	val Project project
	Object ideaHome
	String ideaVersion
	Object sandboxDir
	DownloadIdea downloadTask
	
	def FileCollection getIdeaLibs() {
		project.fileTree(project.file(ideaHome) + "/lib").builtBy(downloadTask).include("*.jar") as FileCollection
	}
	
	def File getIdeaHome() {
		project.file(ideaHome)
	}
	
	def File getSourcesZip() {
		project.file(ideaHome) / 'sources.zip'
	}
}
