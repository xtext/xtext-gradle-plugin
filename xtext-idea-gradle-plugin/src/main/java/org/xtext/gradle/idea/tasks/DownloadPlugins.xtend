package org.xtext.gradle.idea.tasks

import groovy.util.XmlSlurper
import groovy.util.slurpersupport.Node
import java.io.File
import java.net.URL
import java.nio.file.Files
import java.util.Set
import java.util.concurrent.Callable
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.Task
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*

@Accessors
class DownloadPlugins extends DefaultTask {
	@OutputDirectory File destinationDir
	IdeaPluginRepositories pluginRepositories
	IdeaPluginDependencies pluginDependencies

	new() {
		outputs.upToDateWhen [
			val existingDirs = destinationDir.list?.toList ?: #[]
			!project.gradle.startParameter.refreshDependencies 
				&& pluginDependencies.forall[existingDirs.contains(id)]
		]
		dependsOn(new Callable<Set<Task>>() {
			override call() throws Exception {
				pluginDependencies.map[project.rootProject.findProject(id)]
					.filterNull
					.map[tasks.getByName("assembleSandbox")]
					.toSet
			}
		})
	}

	@TaskAction
	def download() {
		val urlsByPluginId = collectUrlsByPluginId
		externalPluginDependencies.forEach [
			download(id, urlsByPluginId.get(id))
		]
		pluginDependencies.map[project.rootProject.findProject(id)]
			.filterNull
			.forEach[projectDependency|
				project.copy [
					from(projectDependency.tasks.getByName("assembleSandbox"))
					into(destinationDir)
				]
			]
	}
	
	def externalPluginDependencies() {
		pluginDependencies.filter[
			project.rootProject.findProject(id) == null
		]
	}

	def download(String pluginId, String downloadUrl) {
		val targetFile = destinationDir / '''«pluginId».zip'''
		Files.copy(new URL(downloadUrl).openStream, targetFile.toPath)
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