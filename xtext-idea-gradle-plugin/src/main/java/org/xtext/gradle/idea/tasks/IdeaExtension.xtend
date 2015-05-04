package org.xtext.gradle.idea.tasks

import groovy.lang.Closure
import java.io.File
import java.util.List
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
	DownloadIdeaPlugins downloadPlugins
	
	new (Project project) {
		this.project = project
		pluginRepositories = new IdeaPluginRepositories
		pluginDependencies = new IdeaPluginDependencies
	}
	
	def List<Object> getIdeaLibs() {
		val result = <Object>newArrayList
		result += pluginDependencies.projectDependencies.map [
			project.project(it)
		]
		result.add(externalLibs)
		result
	}
	
	def FileCollection getExternalLibs() {
		new LazilyInitializedFileCollection {
			override createDelegate() {
				val unpackedDependencies = pluginDependencies.externalDependencies.map[
					pluginsCache / id / version
				]
				val dependencyClasses = unpackedDependencies
					.map[project.files(it / "classes")]
					.reduce[FileCollection a, FileCollection b| a.plus(b)]
				val dependencyLibs = unpackedDependencies
					.map[project.fileTree(it / "lib")]
					.reduce[FileCollection a, FileCollection b| a.plus(b)]
				#[ideaCoreLibs, dependencyClasses, dependencyLibs].filterNull.reduce[a, b| a.plus(b)]
			}
			
			override getBuildDependencies() {
				[#{downloadIdea, downloadPlugins}]
			}
		}
	}
	
	def FileCollection getIdeaCoreLibs() {
		project.fileTree(getIdeaHome + "/lib")
			.builtBy(downloadIdea).include("*.jar") as FileCollection
	}
	
	def FileCollection getIdeaRunClasspath() {
		ideaCoreLibs.plus(toolsJar)
	}
	
	def toolsJar() {
		project.files('''«System.getProperty("java.home")»/../lib/tools.jar''')
	}
	
	def File getIdeaHome() {
		if (ideaHome == null) {
			project.gradle.gradleUserHomeDir / "ideaSDK" / ideaVersion
		} else {
			project.file(ideaHome) 
		}
	}
	
	def File getPluginsCache() {
		project.gradle.gradleUserHomeDir / "ideaPluginDependencies"
	}
	
	def File getSourcesZip() {
		getIdeaHome / 'sources.zip'
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
	
	def ExternalIdeaPluginDependency id(String id) {
		val dependency = new ExternalIdeaPluginDependency(id)
		externalDependencies += dependency
		dependency
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
	
	def version(String version) {
		this.version = version
	}
}