package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.xtext.gradle.idea.tasks.IdeaRepository

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*
import org.gradle.api.plugins.BasePlugin

class IdeaRepositoryPlugin implements Plugin<Project> {
	public static val IDEA_REPOSITORY_TASK_NAME = "ideaRepository"

	override apply(Project project) {
		project.plugins.<IdeaDevelopmentPlugin>apply(IdeaDevelopmentPlugin)
		val repositoryTask = project.tasks.create(IDEA_REPOSITORY_TASK_NAME, IdeaRepository) [
			description = "Creates an Idea repository from which plugins can be installed"
			group = BasePlugin.BUILD_GROUP
			into(project.buildDir / 'ideaRepository')
		]
		project.allprojects [ p |
			p.plugins.withType(IdeaPluginPlugin) [
				repositoryTask.from(p.tasks.findByName(IdeaPluginPlugin.IDEA_ZIP_TASK_NAME))
			]
		]
	}
}