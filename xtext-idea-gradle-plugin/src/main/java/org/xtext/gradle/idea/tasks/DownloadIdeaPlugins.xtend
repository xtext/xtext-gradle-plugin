package org.xtext.gradle.idea.tasks

import groovy.util.XmlSlurper
import groovy.util.slurpersupport.Node
import java.io.File
import java.net.URL
import java.nio.file.Files
import java.util.Date
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
			pluginsToBeDownloaded.exists [needsRedownload]
		]
	}

	@TaskAction
	def download() {
		val urlsByPluginId = collectUrlsByPluginId
		pluginsToBeDownloaded.filter[needsRedownload].forEach [
			download(urlsByPluginId.get(it))
		]
	}

	def download(DownloadIdeaPlugins.PluginRequest plugin, String downloadUrl) {
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
			plugin.lastDownloaded = new Date
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
	
	private def pluginsToBeDownloaded() {
		pluginDependencies.externalDependencies.map[new PluginRequest(id, version)]
	}
	
	private def pluginFolder(DownloadIdeaPlugins.PluginRequest plugin) {
		destinationDir / plugin.id / plugin.version
	}
	
	private def lastDownloadedFile(DownloadIdeaPlugins.PluginRequest plugin) {
		plugin.pluginFolder / '.lastDownloaded'
	}
	
	private def getLastDownloaded(DownloadIdeaPlugins.PluginRequest plugin) {
		plugin.lastDownloadedFile.lastModified
	}
	
	private def setLastDownloaded(DownloadIdeaPlugins.PluginRequest plugin, Date lastModified) {
		val file = plugin.lastDownloadedFile
		file.createNewFile
		file.lastModified = lastModified.time
	}
	
	private def isSnapshot(DownloadIdeaPlugins.PluginRequest plugin) {
		plugin.version.endsWith("-SNAPSHOT")
	}
	
	private def needsRedownload(DownloadIdeaPlugins.PluginRequest plugin) {
		project.gradle.startParameter.isRefreshDependencies || plugin.lastDownloaded == 0 || plugin.isSnapshot && plugin.lastDownloaded < new Date().time - 1000 * 60 * 60 * 24
	}
	
	@Data
	private static class PluginRequest {
		String id
		String version
	}
}