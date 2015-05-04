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
import org.gradle.api.plugins.BasePlugin
import org.gradle.api.GradleException
import org.gradle.api.execution.TaskExecutionGraphListener
import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*
class IdeaComponentPlugin implements Plugin<Project> {
	public static val IDEA_PROVIDED_CONFIGURATION_NAME = "ideaProvided"
	public static val ASSEMBLE_SANDBOX_TASK_NAME = "assembleSandbox"
	public static val RUN_IDEA_TASK_NAME = "runIdea"
	static val TaskExecutionGraphListener runIdeaValidator = [graph| 
		val runTasks = graph.allTasks.filter[name == RUN_IDEA_TASK_NAME]
		if (runTasks.size > 1) {
			throw new GradleException('''
				There are multiple «RUN_IDEA_TASK_NAME» tasks in the task graph.
				When calling runIdea on an aggregate project, make sure you fully qualify the task name,
				e.g. ':myProject:runIdea'
			'''
			)
		}
	]

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
			runtimeClasspath = runtimeClasspath.plus(ideaProvided).plus(idea.toolsJar)
		]

		val assembleSandboxTask = project.tasks.create(ASSEMBLE_SANDBOX_TASK_NAME, AssembleSandbox) => [
			description = "Creates a folder containing the plugins to run Idea with"
			group = BasePlugin.BUILD_GROUP
		]

		project.afterEvaluate [
			idea.ideaLibs.forEach[
				project.dependencies.add(ideaProvided.name, it)
			]
			assembleSandboxTask.destinationDir = idea.sandboxDir
			assembleSandboxTask.plugin.into(project.name)
			idea.pluginDependencies.externalDependencies.forEach [
				assembleSandboxTask.rootSpec.addChild.into(id).from(idea.pluginsCache / id / version)
			]
			val upstreamSandBoxTasks = idea.pluginDependencies.projectDependencies
				.map[project.project(id)]
				.map[(tasks.getAt(ASSEMBLE_SANDBOX_TASK_NAME) as AssembleSandbox)]
			assembleSandboxTask.from(upstreamSandBoxTasks)
			assembleSandboxTask.exclude("*.zip")
		]

		val runIdea = project.tasks.create(RUN_IDEA_TASK_NAME, RunIdea) => [
			dependsOn(assembleSandboxTask)
			description = "Runs Intellij IDEA with this project and its dependencies installed"
			group = IdeaDevelopmentPlugin.IDEA_TASK_GROUP
		]
		project.afterEvaluate [
			runIdea.sandboxDir = idea.sandboxDir
			runIdea.ideaHome = idea.ideaHome
			runIdea.classpath = idea.ideaRunClasspath
		]
		
		project.gradle.taskGraph.addTaskExecutionGraphListener(runIdeaValidator)

		project.tasks.withType(Test).all [
			dependsOn(assembleSandboxTask)
			systemProperty("idea.home.path", idea.ideaHome)
			systemProperty("idea.plugins.path", idea.sandboxDir)
		]

		project.plugins.withType(EclipsePlugin) [
			val eclipseClasspath = project.tasks.getByName(EclipsePlugin.ECLIPSE_CP_TASK_NAME)
			eclipseClasspath.dependsOn(idea.downloadIdea, idea.downloadPlugins)
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
		project.plugins.withType(IdeaAggregatorPlugin) [
			throw new GradleException("Do not apply idea-component and idea-aggregator to the same project")
		]
	}
}