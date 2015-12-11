package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.BasePlugin
import org.xtext.gradle.idea.tasks.IdeaExtension
import org.xtext.gradle.idea.tasks.IdeaRepository

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*

class IdeaRepositoryPlugin implements Plugin<Project> {
	public static val IDEA_REPOSITORY_TASK_NAME = "ideaRepository"

	override apply(Project project) {
		project.plugins.<IdeaDevelopmentPlugin>apply(IdeaDevelopmentPlugin)
		val repositoryTask = project.tasks.create(IDEA_REPOSITORY_TASK_NAME, IdeaRepository) [
			description = "Creates an Idea repository from which plugins can be installed"
			group = BasePlugin.BUILD_GROUP
			into(project.buildDir / 'ideaRepository')
		]
		val idea = project.extensions.getByType(IdeaExtension)
		project.afterEvaluate[
			idea.pluginDependencies.projectDependencies
			.map[project.project(id)]
			.map[ideaZipTask]
			.forEach[zip|
				repositoryTask.from(zip)
			]
		]
		project.plugins.withType(IdeaPluginPlugin) [
			repositoryTask.from(project.ideaZipTask)
		]
	}
	
	def getIdeaZipTask(Project it) {
		tasks.findByName(IdeaPluginPlugin.IDEA_ZIP_TASK_NAME)
	}
}