package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.tasks.Sync
import org.xtext.gradle.idea.tasks.AssembleSandbox
import org.xtext.gradle.idea.tasks.IdeaExtension
import org.xtext.gradle.idea.tasks.RunIdea

class IdeaAggregatorPlugin implements Plugin<Project> {

	override apply(Project project) {
		project.plugins.<IdeaDevelopmentPlugin>apply(IdeaDevelopmentPlugin)
		val idea = project.extensions.getByType(IdeaExtension)
		
		val aggregateSandbox = project.tasks.create("aggregateSandbox", Sync)
		val runIdea = project.tasks.create("runIdea", RunIdea)
		project.afterEvaluate [
			aggregateSandbox.into(idea.sandboxDir)
			aggregateSandbox.from(subprojects.map[tasks.withType(AssembleSandbox)].flatten.map[outputs])
			
			runIdea.dependsOn(aggregateSandbox)
			runIdea.sandboxDir = idea.sandboxDir
			runIdea.ideaHome = idea.ideaHome
			runIdea.classpath = idea.ideaRunClasspath
		]
	}
}