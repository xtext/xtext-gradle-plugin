package org.xtext.gradle.tasks;

import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.file.SourceDirectorySet;
import org.gradle.api.internal.FactoryNamedDomainObjectContainer
import org.gradle.api.internal.file.DefaultSourceDirectorySet
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.tasks.SourceSet
import org.gradle.internal.reflect.Instantiator
import org.gradle.util.ConfigureUtil;

class XtextExtension {
	String version = "2.5.3"
	String encoding = "UTF-8"
	SourceDirectorySet sources
	NamedDomainObjectContainer<Language> languages;

	private Project project

	XtextExtension(Project project, FileResolver fileResolver) {
		this.project = project
		languages = project.container(Language){name -> new Language(project, name)}
		sources = new DefaultSourceDirectorySet("xtext", fileResolver)
	}

	def languages(Closure closure) {
		languages.configure(closure)
	}

	def sources(Closure closure) {
		ConfigureUtil.configure(closure, sources)
	}
}

class Language {
	String name;
	String setup
	boolean consumesJava
	NamedDomainObjectContainer<OutputConfiguration> outputs
	Map<String, String> properties

	private Project project

	Language(Project project, String name) {
		this.name = name
		this.project = project
		outputs = project.container(OutputConfiguration)
	}

	def properties(Map<String, String> properties) {
		this.properties = properties
	}

	def outputs(Closure closure) {
		outputs.configure(closure)
	}

	def OutputConfiguration getOutput() {
		outputs.maybeCreate("DEFAULT_OUTPUT")
	}

	def output(Closure closure) {
		ConfigureUtil.configure(closure, getOutput())
	}
}

class OutputConfiguration {
	String name
	def dir
	SourceSet javaSourceSet

	OutputConfiguration(String name) {
		this.name = name
	}
	
	def producesJavaFor(SourceSet javaSourceSet) {
		setJavaSourceSet(javaSourceSet)
	}
}
