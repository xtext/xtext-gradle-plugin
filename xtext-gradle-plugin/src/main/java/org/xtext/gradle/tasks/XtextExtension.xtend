package org.xtext.gradle.tasks;

import groovy.lang.Closure
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.file.SourceDirectorySet
import org.gradle.api.internal.file.DefaultSourceDirectorySet
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.tasks.SourceSet
import org.gradle.util.ConfigureUtil

class XtextExtension {
	@Accessors String version = "2.7.2"
	@Accessors String encoding = "UTF-8"
	@Accessors SourceDirectorySet sources
	@Accessors NamedDomainObjectContainer<Language> languages;

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
	@Accessors String name;
	@Accessors String setup
	@Accessors boolean consumesJava
	@Accessors NamedDomainObjectContainer<OutputConfiguration> outputs

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
	@Accessors String name
	@Accessors Object dir
	@Accessors SourceSet javaSourceSet

	new(String name) {
		this.name = name
	}

	def producesJavaFor(SourceSet javaSourceSet) {
		setJavaSourceSet(javaSourceSet)
	}
}
