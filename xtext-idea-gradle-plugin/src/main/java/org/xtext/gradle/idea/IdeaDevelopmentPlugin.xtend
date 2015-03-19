package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.xtext.gradle.idea.tasks.DownloadIdea
import org.xtext.gradle.idea.tasks.IdeaExtension

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*
import org.xtext.gradle.idea.tasks.DownloadPlugins

class IdeaDevelopmentPlugin implements Plugin<Project> {

	override apply(Project project) {
		val idea = project.extensions.create("ideaDevelopment", IdeaExtension, project) => [
			ideaHome = project.rootDir / "ideaHome"
			ideaVersion = "140.2683.2"
		]
		val downloadIdea = project.tasks.create("downloadIdea", DownloadIdea)
		idea.downloadIdea= downloadIdea
		project.afterEvaluate [
			downloadIdea.ideaHome = idea.ideaHome
			downloadIdea.ideaVersion = idea.ideaVersion
		]
		
		val downloadPlugins = project.tasks.create("downloadPlugins", DownloadPlugins)
		idea.downloadPlugins = downloadPlugins
		project.afterEvaluate[
			downloadPlugins.destinationDir = project.buildDir / "pluginDependencies"
			downloadPlugins.pluginRepositories = idea.pluginRepositories
			downloadPlugins.pluginDependencies = idea.pluginDependencies
		]
	}
}