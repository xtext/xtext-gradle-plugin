package org.xtext.gradle.idea.tasks

import groovy.util.XmlSlurper
import groovy.util.slurpersupport.Node
import java.io.File
import java.net.URL
import java.nio.file.Files
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*
import java.nio.file.StandardCopyOption

@Accessors
class DownloadPlugins extends DefaultTask {
	@OutputDirectory File destinationDir
	IdeaPluginRepositories pluginRepositories
	IdeaPluginDependencies pluginDependencies

	new() {
		outputs.upToDateWhen [
			val existingDirs = destinationDir.list?.toList ?: #[]
			!project.gradle.startParameter.refreshDependencies 
				&& externalPluginDependencies.forall[existingDirs.contains(id)]
		]
	}

	@TaskAction
	def download() {
		val urlsByPluginId = collectUrlsByPluginId
		externalPluginDependencies.forEach [
			download(id, urlsByPluginId.get(id))
		]
	}
	
	def externalPluginDependencies() {
		pluginDependencies.externalDependencies
	}

	def download(String pluginId, String downloadUrl) {
		val targetFile = destinationDir / '''«pluginId».zip'''
		Files.copy(new URL(downloadUrl).openStream, targetFile.toPath, StandardCopyOption.REPLACE_EXISTING)
		project.copy [
			from(project.zipTree(targetFile))
			into(destinationDir)
		]
	}

	def collectUrlsByPluginId() {
		newHashMap(pluginRepositories.map[
			val result = new XmlSlurper().parse(url)
			result.childNodes.toIterable.filter(Node)
				.map[attributes.get("id") as String -> attributes.get("url") as String]
		].flatten)
	}
}