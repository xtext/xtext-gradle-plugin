package org.xtext.gradle.idea

import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.Configuration
import org.gradle.api.execution.TaskExecutionGraphListener
import org.gradle.api.plugins.BasePlugin
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.gradle.api.tasks.testing.Test
import org.gradle.plugins.ide.eclipse.EclipsePlugin
import org.gradle.plugins.ide.eclipse.model.Classpath
import org.gradle.plugins.ide.eclipse.model.EclipseModel
import org.gradle.plugins.ide.eclipse.model.Library
import org.gradle.plugins.ide.eclipse.model.internal.FileReferenceFactory
import org.gradle.plugins.ide.idea.IdeaPlugin
import org.gradle.plugins.ide.idea.model.IdeaModel
import org.xtext.gradle.idea.tasks.AssembleSandbox
import org.xtext.gradle.idea.tasks.DownloadIdea
import org.xtext.gradle.idea.tasks.DownloadIdeaPlugins
import org.xtext.gradle.idea.tasks.IdeaExtension
import org.xtext.gradle.idea.tasks.RunIdea

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*
import org.gradle.api.plugins.JavaBasePlugin

class IdeaDevelopmentPlugin implements Plugin<Project> {
	public static val IDEA_DEVELOPMENT_EXTENSION_NAME = "ideaDevelopment"
	public static val IDEA_TASK_GROUP = "Intellij Idea"
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
	
	IdeaExtension idea
	DownloadIdea downloadIdea
	DownloadIdeaPlugins downloadPlugins
	AssembleSandbox assembleSandbox
	RunIdea runIdea
	
	JavaPluginConvention java
	Configuration ideaProvided

	override apply(Project project) {
		idea = project.extensions.create(IDEA_DEVELOPMENT_EXTENSION_NAME, IdeaExtension, project)
		configureDownloadIdeaTask(project)
		configureDownloadPluginsTask(project)
		configureassembleSandboxTask(project)
		configureRunIdeaTask(project)
		integrateWithJavaPlugin(project)
	}
	
	private def configureDownloadIdeaTask(Project project) {
		downloadIdea = project.tasks.create("downloadIdea", DownloadIdea) => [
			group = IDEA_TASK_GROUP
			description = "Downloads Intellij Idea"
			project.afterEvaluate [p|
				ideaHome = idea.ideaHome
				ideaVersion = idea.ideaVersion
			]
		]
		idea.downloadIdea= downloadIdea
	}
	
	private def configureDownloadPluginsTask(Project project) {
		downloadPlugins = project.tasks.create("downloadIdeaPlugins", DownloadIdeaPlugins) => [
			description = "Downloads Idea plugin dependencies"
			group = IDEA_TASK_GROUP
			project.afterEvaluate[p|
				destinationDir = idea.pluginsCache
				pluginRepositories = idea.pluginRepositories
				pluginDependencies = idea.pluginDependencies
			]
		]
		idea.downloadPlugins = downloadPlugins
	}
	
	private def configureassembleSandboxTask(Project project) {
		assembleSandbox = project.tasks.create(ASSEMBLE_SANDBOX_TASK_NAME, AssembleSandbox) => [
			description = "Creates a folder containing the plugins to run Idea with"
			group = BasePlugin.BUILD_GROUP
			project.afterEvaluate[p|
				destinationDir = idea.sandboxDir
				plugin.into(project.name)
				idea.pluginDependencies.externalDependencies.forEach [dependency|
					rootSpec.addChild
						.into(dependency.id)
						.from(idea.pluginsCache / dependency.id / dependency.version)
				]
				idea.pluginDependencies.endorsedDependencies.forEach [dependency|
					rootSpec.addChild
						.into(dependency.id)
						.from(idea.ideaHome / "plugins" / dependency.id)
				]
				val upstreamSandBoxTasks = idea.pluginDependencies.projectDependencies
					.map[project.project(id)]
					.map[tasks.getAt(ASSEMBLE_SANDBOX_TASK_NAME)]
				from(upstreamSandBoxTasks)
			]
		]
	}
	
	private def configureRunIdeaTask(Project project) {
		runIdea = project.tasks.create(RUN_IDEA_TASK_NAME, RunIdea) => [
			dependsOn(assembleSandbox)
			description = "Runs Intellij IDEA with this project and its dependencies installed"
			group = IdeaDevelopmentPlugin.IDEA_TASK_GROUP
			project.afterEvaluate [p|
				sandboxDir = idea.sandboxDir
				ideaHome = idea.ideaHome
				classpath = idea.ideaRunClasspath
			]
		]
		project.gradle.taskGraph.addTaskExecutionGraphListener(runIdeaValidator)
	}
	
	private def integrateWithJavaPlugin(Project project) {
		project.plugins.withType(JavaBasePlugin) [
			java = project.convention.getPlugin(JavaPluginConvention)
			project.plugins.withType(JavaPlugin) [
				addIdeaProvidedDependencies(project)
				addIdeaDependenciesToEclipseClasspath(project)
				addIdeaDependenciesToIntelliJClasspath(project)
				adjustTestEnvironment(project)
			]
		]
	}
	
	private def addIdeaProvidedDependencies(Project project) {
		ideaProvided = project.configurations.create(IDEA_PROVIDED_CONFIGURATION_NAME)
		java.sourceSets.all [
			compileClasspath = compileClasspath.plus(ideaProvided)
			runtimeClasspath = runtimeClasspath.plus(ideaProvided).plus(idea.toolsJar)
		]
		project.afterEvaluate [
			idea.ideaLibs.forEach[
				project.dependencies.add(ideaProvided.name, it)
			]
		]
	}
	
	private def adjustTestEnvironment(Project project) {
		project.afterEvaluate[
			project.tasks.withType(Test).all [
				dependsOn(assembleSandbox)
				systemProperty("idea.home.path", idea.ideaHome)
				systemProperty("idea.plugins.path", idea.sandboxDir)
				systemProperty('idea.system.path', project.buildDir + "/idea-test-system")
				systemProperty('idea.config.path', project.buildDir + "/idea-test-config")
			]
		]
	}
	
	private def addIdeaDependenciesToEclipseClasspath(Project project) {
		project.plugins.withType(EclipsePlugin) [
			val eclipseClasspath = project.tasks.getByName(EclipsePlugin.ECLIPSE_CP_TASK_NAME)
			eclipseClasspath.dependsOn(idea.downloadIdea, idea.downloadPlugins)
			project.extensions.getByType(EclipseModel).classpath => [
				plusConfigurations.add(ideaProvided)

				val fileReferenceFactory = new FileReferenceFactory
				file.whenMerged.add [ Classpath it |
					entries.filter(Library).filter[idea.ideaCoreLibs.contains(library.file)].forEach [
						sourcePath = fileReferenceFactory.fromFile(idea.sourcesZip)
					]
				]
			]
		]
	}
	
	private def addIdeaDependenciesToIntelliJClasspath(Project project) {
		project.plugins.withType(IdeaPlugin) [
			project.tasks.getByName("ideaModule").dependsOn(idea.downloadIdea, idea.downloadPlugins)
			val ideaModel = project.extensions.getByType(IdeaModel)
			ideaModel.module.scopes.get("PROVIDED").get("plus").add(ideaProvided)
		]
	}
}
