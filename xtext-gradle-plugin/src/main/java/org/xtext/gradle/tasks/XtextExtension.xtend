package org.xtext.gradle.tasks;

import de.oehme.xtend.contrib.Property
import groovy.lang.Closure
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.file.SourceDirectorySet
import org.gradle.api.internal.file.DefaultSourceDirectorySet
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.tasks.SourceSet
import org.gradle.util.ConfigureUtil

class XtextExtension {
	@Property String version = "2.6.0"
	@Property String encoding = "UTF-8"
	@Property SourceDirectorySet sources
	@Property boolean fork
	@Property NamedDomainObjectContainer<Language> languages;

	private Project project

	new(Project project, FileResolver fileResolver) {
		this.project = project
		languages = project.container(Language)[name|new Language(project, name)]
		sources = new DefaultSourceDirectorySet("xtext", fileResolver)
	}

	def languages(Closure<?> closure) {
		languages.configure(closure)
	}

	def sources(Closure<?> closure) {
		ConfigureUtil.configure(closure, sources)
	}
}

class Language {
	@Property String name;
	@Property String setup
	@Property boolean consumesJava
	@Property NamedDomainObjectContainer<OutputConfiguration> outputs

	private Project project

	new(Project project, String name) {
		this.name = name
		this.project = project
		outputs = project.container(OutputConfiguration)
	}

	def outputs(Closure<?> closure) {
		outputs.configure(closure)
	}

	def OutputConfiguration getOutput() {
		outputs.maybeCreate("DEFAULT_OUTPUT")
	}

	def output(Closure<?> closure) {
		ConfigureUtil.configure(closure, output)
	}
}

class OutputConfiguration {
	@Property String name
	@Property Object dir
	@Property SourceSet javaSourceSet

	new(String name) {
		this.name = name
	}

	def producesJavaFor(SourceSet javaSourceSet) {
		setJavaSourceSet(javaSourceSet)
	}
}
