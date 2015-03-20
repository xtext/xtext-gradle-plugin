package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.tasks.Sync
import org.xtext.gradle.idea.tasks.IdeaExtension
import org.xtext.gradle.idea.tasks.RunIdea

class IdeaAggregatorPlugin implements Plugin<Project> {
	public static val AGGREGATE_SANDBOX_TASK_NAME = "aggregateSandbox"

	override apply(Project project) {
		project.plugins.<IdeaDevelopmentPlugin>apply(IdeaDevelopmentPlugin)
		val idea = project.extensions.getByType(IdeaExtension)

		val aggregateSandbox = project.tasks.create(AGGREGATE_SANDBOX_TASK_NAME, Sync)
		val runIdea = project.tasks.create(IdeaComponentPlugin.RUN_IDEA_TASK_NAME, RunIdea)
		project.afterEvaluate [
			aggregateSandbox.into(idea.sandboxDir)
			aggregateSandbox.from(subprojects
				.filter[plugins.hasPlugin(IdeaPluginPlugin)]
				.map [tasks.getAt(IdeaComponentPlugin.ASSEMBLE_SANDBOX_TASK_NAME)]
				.map[outputs]
			)
			runIdea.dependsOn(aggregateSandbox)
			runIdea.sandboxDir = idea.sandboxDir
			runIdea.ideaHome = idea.ideaHome
			runIdea.classpath = idea.ideaRunClasspath
		]
	}
}