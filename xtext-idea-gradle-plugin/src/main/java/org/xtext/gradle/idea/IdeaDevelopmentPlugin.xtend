package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.xtext.gradle.idea.tasks.DownloadIdea
import org.xtext.gradle.idea.tasks.IdeaExtension

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*
import org.xtext.gradle.idea.tasks.DownloadPlugins

class IdeaDevelopmentPlugin implements Plugin<Project> {
	public static val IDEA_DEVELOPMENT_EXTENSION_NAME = "ideaDevelopment"

	override apply(Project project) {
		val idea = project.extensions.create(IDEA_DEVELOPMENT_EXTENSION_NAME, IdeaExtension, project) => [
			ideaHome = project.rootDir / "ideaHome"
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