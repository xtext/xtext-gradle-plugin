package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.xtext.gradle.idea.tasks.IdeaRepository
import org.xtext.gradle.idea.tasks.IdeaZip

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*

class IdeaRepositoryPlugin implements Plugin<Project> {

	override apply(Project project) {
		project.plugins.<IdeaDevelopmentPlugin>apply(IdeaDevelopmentPlugin)
		val repositoryTask = project.tasks.create("ideaRepository", IdeaRepository) [
			into(project.buildDir / 'ideaRepository')
		]
		project.allprojects [
			tasks.withType(IdeaZip) [ zip |
				repositoryTask.from(zip)
			]
		]
	}
}