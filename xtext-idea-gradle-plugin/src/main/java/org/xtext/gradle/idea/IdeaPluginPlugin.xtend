package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.tasks.bundling.Zip
import org.xtext.gradle.idea.tasks.AssembleSandbox

class IdeaPluginPlugin implements Plugin<Project> {
	public static val IDEA_ZIP_TASK_NAME = "ideaZip"

	override apply(Project project) {
		project.plugins.<IdeaComponentPlugin>apply(IdeaComponentPlugin)
		project.tasks.create(IDEA_ZIP_TASK_NAME, Zip) [
			val assembleSandbox = project.tasks.getAt(IdeaComponentPlugin.ASSEMBLE_SANDBOX_TASK_NAME) as AssembleSandbox
			with(assembleSandbox.plugin)
		]
	}
}