package org.xtext.gradle.idea

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.gradle.api.tasks.testing.Test
import org.gradle.plugins.ide.eclipse.EclipsePlugin
import org.gradle.plugins.ide.eclipse.model.Classpath
import org.gradle.plugins.ide.eclipse.model.EclipseModel
import org.gradle.plugins.ide.eclipse.model.Library
import org.gradle.plugins.ide.eclipse.model.internal.FileReferenceFactory
import org.xtext.gradle.idea.tasks.AssembleSandbox
import org.xtext.gradle.idea.tasks.IdeaExtension
import org.xtext.gradle.idea.tasks.RunIdea

class IdeaComponentPlugin implements Plugin<Project> {
	public static val IDEA_PROVIDED_CONFIGURATION_NAME = "ideaProvided"
	public static val ASSEMBLE_SANDBOX_TASK_NAME = "assembleSandbox"
	public static val RUN_IDEA_TASK_NAME = "runIdea"

	override apply(Project project) {
		project.plugins.<IdeaDevelopmentPlugin>apply(IdeaDevelopmentPlugin)
		project.plugins.<JavaPlugin>apply(JavaPlugin)
		val idea = project.extensions.getByType(IdeaExtension)
		val java = project.convention.getPlugin(JavaPluginConvention)

		val compile = project.configurations.getAt(JavaPlugin.COMPILE_CONFIGURATION_NAME)
		compile.exclude(#{"module" -> "guava"})
		compile.exclude(#{"module" -> "log4j"})

		val ideaProvided = project.configurations.create(IDEA_PROVIDED_CONFIGURATION_NAME)
		java.sourceSets.all [
			compileClasspath = compileClasspath.plus(ideaProvided)
		]
		project.afterEvaluate [
			project.dependencies.add(ideaProvided.name, idea.ideaLibs)
		]

		val mainSourceSet = java.sourceSets.getByName("main")
		val providedDependencies = project.configurations.getAt(IdeaComponentPlugin.IDEA_PROVIDED_CONFIGURATION_NAME)
		val runtimeDependencies = project.configurations.getAt(JavaPlugin.RUNTIME_CONFIGURATION_NAME)

		val assembleSandboxTask = project.tasks.create(ASSEMBLE_SANDBOX_TASK_NAME, AssembleSandbox) [
			classes.from(mainSourceSet.output)
			libraries.from(runtimeDependencies.filter [ candidate |
				!providedDependencies.exists[candidate.name == name]
			])
			metaInf.from("META-INF")
		]

		project.afterEvaluate [
			assembleSandboxTask.destinationDir = idea.sandboxDir
			assembleSandboxTask.plugin.into(project.name)
			assembleSandboxTask.from(idea.downloadPlugins.destinationDir)
			val projectDependencies = idea.pluginDependencies
				.map[project.rootProject.findProject(id)].filterNull
				.map[(tasks.getAt(ASSEMBLE_SANDBOX_TASK_NAME) as AssembleSandbox).destinationDir]
			assembleSandboxTask.from(projectDependencies)
			assembleSandboxTask.exclude("*.zip")
		]

		val runIdea = project.tasks.create(RUN_IDEA_TASK_NAME, RunIdea)
		runIdea.dependsOn(assembleSandboxTask)
		project.afterEvaluate [
			runIdea.sandboxDir = idea.sandboxDir
			runIdea.ideaHome = idea.ideaHome
			runIdea.classpath = idea.ideaRunClasspath
		]

		project.tasks.withType(Test).all [
			jvmArgs(
				'''-Didea.home.path=«idea.ideaHome»''',
				'''-Didea.config.path=«idea.ideaHome»/test''',
				'''-Didea.system.path=«idea.ideaHome»/test-system''',
				'''-Didea.plugins.path=«idea.sandboxDir»'''
			)
		]

		project.plugins.withType(EclipsePlugin) [
			project.tasks.getByName(EclipsePlugin.ECLIPSE_CP_TASK_NAME).dependsOn(idea.downloadIdea)
			project.extensions.getByType(EclipseModel).classpath => [
				plusConfigurations.add(ideaProvided)

				val fileReferenceFactory = new FileReferenceFactory
				val sourceZip = idea.sourcesZip
				file.whenMerged.add [ Classpath it |
					entries.filter(Library).filter[idea.ideaCoreLibs.contains(library.file)].forEach [
						sourcePath = fileReferenceFactory.fromFile(sourceZip)
					]
				]
			]
		]
	}
}