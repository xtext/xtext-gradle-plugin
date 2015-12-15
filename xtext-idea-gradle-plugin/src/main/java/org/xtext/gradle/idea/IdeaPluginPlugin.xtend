package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.BasePlugin
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.tasks.bundling.Zip
import org.xtext.gradle.idea.tasks.AssembleSandbox
import java.util.regex.Pattern
import java.io.File

class IdeaPluginPlugin implements Plugin<Project> {
	public static val IDEA_ZIP_TASK_NAME = "ideaZip"
	private static val ARTIFACT_ID = Pattern.compile("(.*?)(-.*)?\\.jar")
	
	override apply(Project project) {
		project.apply[
			plugin(IdeaDevelopmentPlugin)
			plugin(JavaPlugin)
		]
		val providedDependencies = project.configurations.getAt(IdeaDevelopmentPlugin.IDEA_PROVIDED_CONFIGURATION_NAME)
		val runtimeDependencies = project.configurations.getAt(JavaPlugin.RUNTIME_CONFIGURATION_NAME)
		val assembleSandbox = project.tasks.getAt(IdeaDevelopmentPlugin.ASSEMBLE_SANDBOX_TASK_NAME) as AssembleSandbox

		val jar = project.tasks.getAt(JavaPlugin.JAR_TASK_NAME)
		assembleSandbox => [
			libraries.from(jar)
			libraries.from(runtimeDependencies.filter [ candidate |
				!providedDependencies.exists[hasSameArtifactId(candidate, it)]
			])
			metaInf.from("META-INF")
		]

		val ideaZip = project.tasks.create(IDEA_ZIP_TASK_NAME, Zip) [
			description = "Creates an installable archive of this plugin"
			group = BasePlugin.BUILD_GROUP
			with(assembleSandbox.plugin)
		]
		project.tasks.getAt(BasePlugin.ASSEMBLE_TASK_NAME).dependsOn(ideaZip)
	}
	
	private def hasSameArtifactId(File file1, File file2) {
		file1.artifactId == file2.artifactId
	}
	
	private def getArtifactId(File file) {
		val matcher = ARTIFACT_ID.matcher(file.name)
		if (matcher.matches) matcher.group(1) else null
	}
	
}