package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.gradle.api.tasks.bundling.Zip
import org.xtext.gradle.idea.tasks.AssembleSandbox

class IdeaPluginPlugin implements Plugin<Project> {
	public static val IDEA_ZIP_TASK_NAME = "ideaZip"

	override apply(Project project) {
		project.plugins.<IdeaComponentPlugin>apply(IdeaComponentPlugin)
		val java = project.convention.getPlugin(JavaPluginConvention)
		val mainSourceSet = java.sourceSets.getByName("main")
		val providedDependencies = project.configurations.getAt(IdeaComponentPlugin.IDEA_PROVIDED_CONFIGURATION_NAME)
		val runtimeDependencies = project.configurations.getAt(JavaPlugin.RUNTIME_CONFIGURATION_NAME)
		val assembleSandbox = project.tasks.getAt(IdeaComponentPlugin.ASSEMBLE_SANDBOX_TASK_NAME) as AssembleSandbox
		
		assembleSandbox => [
			classes.from(mainSourceSet.output)
			libraries.from(runtimeDependencies.filter [ candidate |
				!providedDependencies.exists[candidate.name == name]
			])
			metaInf.from("META-INF")
		]

		project.tasks.create(IDEA_ZIP_TASK_NAME, Zip) [
			with(assembleSandbox.plugin)
		]
	}
}