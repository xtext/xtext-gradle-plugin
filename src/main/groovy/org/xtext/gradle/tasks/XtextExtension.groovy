package org.xtext.gradle.tasks;

import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.internal.FactoryNamedDomainObjectContainer
import org.gradle.internal.reflect.Instantiator

class XtextExtension {
	NamedDomainObjectContainer<Language> languages;
	String encoding
	String xtextVersion

	XtextExtension(Project project) {
		languages = project.container(Language){name -> new Language(project, name)}
	}

	def languages(Closure closure) {
		languages.configure(closure)
	}
}

class Language {
	String name;
	String setup
	boolean useJavaSupport
	NamedDomainObjectContainer<OutputConfiguration> outputConfigurations

	private Project project

	Language(Project project, String name) {
		this.name = name
		this.project = project
		outputConfigurations = project.container(OutputConfiguration)
	}

	def outputConfigurations(Closure closure) {
		outputConfigurations.configure(closure)
	}
	
	def OutputConfiguration getOutputConfiguration() {
		outputConfigurations.maybeCreate("DEFAULT_CONFIGURATION")
	}
	
	def outputConfiguration(Closure closure) {
		outputConfigurations.configure(closure)
	}
	
	def setOutputDirectory(Object outputDirectory) {
		getOutputConfiguration().setOutputDirectory(outputDirectory)
	}
}

class OutputConfiguration {
	String name
	def outputDirectory

	OutputConfiguration(String name) {
		this.name = name
	}
}
