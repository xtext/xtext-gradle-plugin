package org.xtext.gradle.idea.tasks

import groovy.lang.Closure
import java.io.File
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Project
import org.gradle.api.file.FileCollection

import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*

@Accessors
class IdeaExtension {
	val Project project
	val IdeaPluginRepositories pluginRepositories
	val IdeaPluginDependencies pluginDependencies
	Object ideaHome
	String ideaVersion
	DownloadIdea downloadIdea
	DownloadPlugins downloadPlugins
	
	new (Project project) {
		this.project = project
		pluginRepositories = new IdeaPluginRepositories
		pluginDependencies = new IdeaPluginDependencies
	}
	
	def FileCollection getIdeaLibs() {
		val unpackedDependencies = pluginDependencies.map[project.file(downloadPlugins.destinationDir) / id]
		val dependencyClasses = unpackedDependencies
			.map[project.files(it / "classes").builtBy(downloadPlugins)]
			.reduce[FileCollection a, FileCollection b| a.plus(b)]
		val dependencyLibs = unpackedDependencies
			.map[project.fileTree(it / "lib").builtBy(downloadPlugins)]
			.reduce[FileCollection a, FileCollection b| a.plus(b)]
		#[ideaCoreLibs, dependencyClasses, dependencyLibs].filterNull.reduce[a, b| a.plus(b)]
	}
	
	def FileCollection getIdeaCoreLibs() {
		project.fileTree(project.file(ideaHome) + "/lib")
			.builtBy(downloadIdea).include("*.jar") as FileCollection
	}
	
	def FileCollection getIdeaRunClasspath() {
		val tools = project.files('''«System.getenv("JAVA_HOME")»/lib/tools.jar''')
		ideaCoreLibs.plus(tools)
	}
	
	def File getIdeaHome() {
		project.file(ideaHome)
	}
	
	def File getSourcesZip() {
		project.file(ideaHome) / 'sources.zip'
	}
	
	def File getSandboxDir() {
		project.buildDir / "ideaSandbox"
	}
	
	def pluginDependencies(Closure<Void> config) {
		project.configure(pluginDependencies as Object, config)
	}
	
	def pluginRepositories(Closure<Void> config) {
		project.configure(pluginRepositories as Object, config)
	}
}

class IdeaPluginRepositories implements Iterable<IdeaPluginRepository> {
	val repositories = <IdeaPluginRepository>newTreeSet[$0.url.compareTo($1.url)]
	
	def void url(String url) {
		repositories += new IdeaPluginRepository(url)
	}
	
	override iterator() {
		repositories.iterator
	}
}

class IdeaPluginDependencies implements Iterable<IdeaPluginDependency> {
	
	val dependencies = <IdeaPluginDependency>newTreeSet[$0.id.compareTo($1.id)]
	var IdeaPluginDependency last
	
	def void id(String id) {
		last = new IdeaPluginDependency(id)
		dependencies += last
	}
	
	def version(String version) {
		last.version = version
		this
	}
	
	override iterator() {
		dependencies.iterator
	}
}

@Accessors
class IdeaPluginRepository {
	val String url
}

@Accessors
class IdeaPluginDependency {
	val String id
	String version
}