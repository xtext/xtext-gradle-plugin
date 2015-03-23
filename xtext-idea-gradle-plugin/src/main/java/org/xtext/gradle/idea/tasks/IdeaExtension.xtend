package org.xtext.gradle.idea.tasks

import groovy.lang.Closure
import java.io.File
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Project
import org.gradle.api.file.FileCollection
import org.gradle.api.internal.file.collections.LazilyInitializedFileCollection

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
		new LazilyInitializedFileCollection {
			
			override createDelegate() {
				val unpackedDependencies = unpackedDependencies
				val dependencyClasses = unpackedDependencies
					.map[project.files(value / "classes")]
					.reduce[FileCollection a, FileCollection b| a.plus(b)]
				val dependencyLibs = unpackedDependencies
					.map[project.fileTree(value / "lib")]
					.reduce[FileCollection a, FileCollection b| a.plus(b)]
				#[ideaCoreLibs, dependencyClasses, dependencyLibs].filterNull.reduce[a, b| a.plus(b)]
			}
			
			override getBuildDependencies() {
				[(unpackedDependencies.map[key] + #{downloadIdea}).toSet]
			}
			
			def unpackedDependencies() {
				pluginDependencies.externalDependencies.map[
					downloadPlugins -> downloadPlugins.destinationDir / id
				]
				+
				pluginDependencies.projectDependencies.map [
					val projectDependency = project.project(it)
					val assembleSandbox = projectDependency.tasks.getAt("assembleSandbox") as AssembleSandbox
					assembleSandbox -> assembleSandbox.destinationDir / projectDependency.name
				]
			}
		}		
	}
	
	def FileCollection getIdeaCoreLibs() {
		project.fileTree(project.file(ideaHome) + "/lib")
			.builtBy(downloadIdea).include("*.jar") as FileCollection
	}
	
	def FileCollection getIdeaRunClasspath() {
		ideaCoreLibs.plus(toolsJar)
	}
	
	def toolsJar() {
		project.files('''«System.getProperty("java.home")»/../lib/tools.jar''')
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

class IdeaPluginDependencies {
	
	@Accessors(PUBLIC_GETTER) val externalDependencies = <ExternalIdeaPluginDependency>newTreeSet[$0.id.compareTo($1.id)]
	@Accessors(PUBLIC_GETTER) val projectDependencies = <String>newHashSet
	var ExternalIdeaPluginDependency last
	
	def void id(String id) {
		last = new ExternalIdeaPluginDependency(id)
		externalDependencies += last
	}
	
	def version(String version) {
		last.version = version
		this
	}
	
	def project(String path) {
		projectDependencies += path
	}
}

@Accessors
class IdeaPluginRepository {
	val String url
}

@Accessors
class ExternalIdeaPluginDependency {
	val String id
	String version
}