package org.xtext.gradle.tasks;

import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.gradle.api.Action
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.tasks.Input
import org.xtext.gradle.tasks.internal.DefaultXtextSourceSet
import org.gradle.internal.reflect.Instantiator

class XtextExtension {
	@Accessors String version = "2.9.0"
	@Accessors val NamedDomainObjectContainer<XtextSourceSet> sourceSets
	@Accessors val NamedDomainObjectContainer<Language> languages;

	private Project project

	new(Project project, FileResolver fileResolver, Instantiator instantiator) {
		this.project = project
		languages = project.container(Language)[name|new Language(name)]
		sourceSets = project.container(XtextSourceSet)[name|new DefaultXtextSourceSet(name, project, fileResolver, instantiator)]
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

@FinalFieldsConstructor
class Language {
	@Input @Accessors val String name
	@Input @Accessors String fileExtension
	@Input @Accessors String setup
	@Input @Accessors Map<String, String> preferences = newHashMap
	String qualifiedName

	@Input
	def getQualifiedName() {
		qualifiedName ?: setup.replace("StandaloneSetup", "")
	}

	def setQualifiedName(String qualifiedName) {
		this.qualifiedName = qualifiedName
	}
	
	def preferences(Map<String, String> preferences) {
		this.preferences.putAll(preferences)
	}
}
