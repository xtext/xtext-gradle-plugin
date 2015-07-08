package org.xtext.gradle.tasks;

import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Action
import org.gradle.api.Named
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Nested
import org.xtext.gradle.tasks.internal.DefaultXtextSourceSet
import org.gradle.util.ConfigureUtil
import groovy.lang.Closure

@Accessors
class XtextExtension {
	String version = "2.9.0"
	val NamedDomainObjectContainer<XtextSourceSet> sourceSets
	val NamedDomainObjectContainer<Language> languages;

	@Accessors(NONE) Project project

	new(Project project, FileResolver fileResolver) {
		this.project = project
		languages = project.container(Language)[name|new Language(name, project)]
		sourceSets = project.container(XtextSourceSet)[name|new DefaultXtextSourceSet(name, project, fileResolver)]
	}

	def languages(Action<? super NamedDomainObjectContainer<Language>> configureAction) {
		configureAction.execute(languages)
	}

	def sourceSets(Action<? super NamedDomainObjectContainer<XtextSourceSet>> configureAction) {
		configureAction.execute(sourceSets)
	}

	def setParseJava(boolean parseJava) {
		if (parseJava) {
			languages.maybeCreate("java") => [
				fileExtension = "java"
				setup = "org.eclipse.xtext.java.JavaSourceLanguageSetup"
				qualifiedName = "org.eclipse.xtext.java.Java"
			]
		} else {
			languages.remove(languages.findByName("java"))
		}
	}
}

@Accessors
class Language implements Named {
	@Input val String name
	@Input String fileExtension
	@Input String setup
	@Input Map<String, String> preferences = newHashMap
	@Nested val NamedDomainObjectContainer<Outlet> outlets
	String qualifiedName
	@Accessors(NONE) val Project project

	new(String name, Project project) {
		this.name = name
		this.project = project
		this.outlets = project.container(Outlet)[outlet| new Outlet(this, outlet)]
	}

	@Input
	def getQualifiedName() {
		qualifiedName ?: setup.replace("StandaloneSetup", "")
	}

	def preferences(Map<String, String> preferences) {
		this.preferences.putAll(preferences)
	}

	def outlets(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, outlets)
	}
	
	def outlet() {
		outlets.maybeCreate(Outlet.DEFAULT_OUTLET)
	}
	
	def outlet(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, outlet)
	}
}

@Accessors
class Outlet implements Named {
	public static val DEFAULT_OUTLET = "DEFAULT_OUTPUT"

	val Language language
	@Input val String name
	@Input boolean hideSyntheticVariables = true
	@Input boolean producesJava = false
	@Input SourceInstaller sourceInstaller = SourceInstaller.SMAP
}

enum SourceInstaller {
	PRIMARY,
	SMAP,
	NONE
}