package org.xtext.gradle.idea.tasks

import groovy.util.XmlSlurper
import groovy.util.slurpersupport.Node
import java.io.File
import java.net.URL
import java.nio.file.Files
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.gradle.api.DefaultTask
import org.gradle.api.tasks.TaskAction

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*

@Accessors
class DownloadIdeaPlugins extends DefaultTask {
	File destinationDir
	IdeaPluginRepositories pluginRepositories
	IdeaPluginDependencies pluginDependencies

	new() {
		onlyIf [
			if (project.gradle.startParameter.refreshDependencies) {
				return true
			}
			externalPluginDependencies.exists [
				! (destinationDir / id / version).exists
			]
		]
	}

	@TaskAction
	def download() {
		val urlsByPluginId = collectUrlsByPluginId
		externalPluginDependencies.forEach [
			val plugin = new PluginRequest(id, version)
			download(plugin, urlsByPluginId.get(plugin))
		]
	}

	def externalPluginDependencies() {
		pluginDependencies.externalDependencies
	}

	def download(PluginRequest plugin, String downloadUrl) {
		usingTmpDir[ tmp |
			val targetFile = tmp / '''«plugin.id».zip'''
			Files.copy(new URL(downloadUrl).openStream, targetFile.toPath)
			val pluginFolder = destinationDir / plugin.id / plugin.version
			project.delete(pluginFolder)
			project.copy [
				into(pluginFolder)
				from(project.zipTree(targetFile))
				eachFile[cutDirs(1)]
				includeEmptyDirs = false
			]
		]
	}

	def collectUrlsByPluginId() {
		newHashMap(pluginRepositories.map [
			val result = new XmlSlurper().parse(url)
			result.childNodes.toIterable.filter(Node).map [
				new PluginRequest(attributes.get("id") as String, attributes.get("version") as String) -> attributes.get("url") as String
			]
		].flatten)
	}
	
	@Data
	private static class PluginRequest {
		String id
		String version
	}
}