package org.xtext.gradle.idea.tasks

import groovy.util.XmlSlurper
import groovy.util.slurpersupport.Node
import java.io.File
import java.net.URL
import java.nio.file.Files
import org.eclipse.xtend.lib.annotations.Accessors
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
			download(id, version, urlsByPluginId.get(id))
		]
	}

	def externalPluginDependencies() {
		pluginDependencies.externalDependencies
	}

	def download(String id, String version, String downloadUrl) {
		usingTmpDir[ tmp |
			val targetFile = tmp / '''«id».zip'''
			Files.copy(new URL(downloadUrl).openStream, targetFile.toPath)
			project.copy [
				into(destinationDir / id / version)
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
				attributes.get("id") as String -> attributes.get("url") as String
			]
		].flatten)
	}
}