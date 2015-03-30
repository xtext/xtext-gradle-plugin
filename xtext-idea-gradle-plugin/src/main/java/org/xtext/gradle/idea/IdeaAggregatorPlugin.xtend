package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.tasks.Sync
import org.xtext.gradle.idea.tasks.IdeaExtension
import org.xtext.gradle.idea.tasks.RunIdea
import org.gradle.api.plugins.BasePlugin

class IdeaAggregatorPlugin implements Plugin<Project> {
	public static val AGGREGATE_SANDBOX_TASK_NAME = "aggregateSandbox"

	override apply(Project project) {
		project.plugins.<IdeaDevelopmentPlugin>apply(IdeaDevelopmentPlugin)
		val idea = project.extensions.getByType(IdeaExtension)

		val aggregateSandbox = project.tasks.create(AGGREGATE_SANDBOX_TASK_NAME, Sync) => [
			description = "Creates a folder containing the plugins to run Idea with"
			group = BasePlugin.BUILD_GROUP
		]
		val runIdea = project.tasks.create(IdeaComponentPlugin.RUN_IDEA_TASK_NAME, RunIdea) => [
			description = "Runs Intellij Idea with all aggregated plugins installed"
			group = IdeaDevelopmentPlugin.IDEA_TASK_GROUP
		]
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