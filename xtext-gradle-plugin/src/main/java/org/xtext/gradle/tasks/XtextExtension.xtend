package org.xtext.gradle.tasks;

import com.google.common.base.CaseFormat
import com.google.common.collect.Lists
import java.util.List
import java.util.Map
import java.util.regex.Pattern
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Action
import org.gradle.api.Named
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.Project
import org.gradle.api.artifacts.Configuration
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.Nested
import org.gradle.api.tasks.Optional
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.protocol.IssueSeverity
import org.xtext.gradle.tasks.internal.DefaultXtextSourceDirectorySet
import org.xtext.gradle.tasks.internal.Version

import static extension org.xtext.gradle.GradleExtensions.*
import java.util.Set
import java.io.File

class XtextExtension {
	@Accessors String version
	@Accessors val NamedDomainObjectContainer<XtextSourceDirectorySet> sourceSets
	@Accessors val NamedDomainObjectContainer<Language> languages;
	@Accessors val List<XtextClasspathInferrer> classpathInferrers;

	Project project

	new(Project project) {
		this.project = project
		sourceSets = project.container(XtextSourceDirectorySet)[name|project.instantiate(typeof(DefaultXtextSourceDirectorySet), name, project, this)]
		languages = project.container(Language)[name|project.instantiate(typeof(Language), name, project)]
		classpathInferrers = Lists.newArrayList
	}

	def sourceSets(Action<? super NamedDomainObjectContainer<XtextSourceDirectorySet>> configureAction) {
		configureAction.execute(sourceSets)
	}

	def languages(Action<? super NamedDomainObjectContainer<Language>> configureAction) {
		configureAction.execute(languages)
	}

	static val LIB_PATTERN = Pattern.compile("org\\.eclipse\\.xtext(\\.xbase\\.lib.*?)?-(.*)\\.jar")

	def String getXtextVersion(FileCollection classpath) {
		if (version !== null)
			return version
		for (file : classpath) {
			val match = getXtextVersion(file)
			if (match !== null) {
				return match
			}
		}
		return null
	}

	package static def String getXtextVersion(File library) {
		val matcher = LIB_PATTERN.matcher(library.name)
		if (matcher.matches) {
			return matcher.group(2)
		}
	}

	def void forceXtextVersion(Configuration dependencies, String xtextVersion) {
		dependencies.resolutionStrategy.eachDependency [
			if (requested.group == "org.eclipse.xtext" || requested.group == "org.eclipse.xtend")
				useVersion(xtextVersion)
		]

		if (project.supportsJvmEcoSystemplugin && Version.parse(xtextVersion)>=  Version.parse("2.17.1")) {
			dependencies.dependencies += project.dependencies.enforcedPlatform('''org.eclipse.xtext:xtext-dev-bom:«xtextVersion»''')
		} else {
			dependencies.resolutionStrategy.eachDependency [
				if (requested.group == "com.google.inject" && requested.name == "guice")
					useVersion("5.0.1")
				if (requested.group == "org.eclipse.platform" && requested.name == "org.eclipse.equinox.common")
					useVersion("3.13.0")
				if (requested.group == "org.eclipse.platform" && requested.name == "org.eclipse.core.runtime")
					useVersion("3.19.0")
			]
		}
	}

	def void makeXtextCompatible(Configuration dependencies) {
		dependencies.exclude(#{'group' -> 'asm'})
	}
}

@Accessors
class Language implements Named {
	@Input val String name
	@Input String qualifiedName
	@Input Set<String> fileExtensions
	@Input String setup
	@Nested val GeneratorConfig generator
	@Nested val DebuggerConfig debugger
	@Nested val ValidatorConfig validator
	@Input Map<String, Object> preferences = newLinkedHashMap

	new(String name, Project project) {
		this.name = name
		this.generator = project.instantiate(typeof(GeneratorConfig), project, this)
		this.debugger = project.instantiate(typeof(DebuggerConfig))
		this.validator = project.instantiate(typeof(ValidatorConfig))
		fileExtensions = newLinkedHashSet(name)
	}

	def getQualifiedName() {
		qualifiedName ?: setup.replace("StandaloneSetup", "")
	}

	@Internal
	@Deprecated
	def getFileExtension() {
		fileExtensions.head
	}

	@Deprecated
	def setFileExtension(String ext) {
		fileExtensions = newLinkedHashSet(ext)
	}

	def generator(Action<GeneratorConfig> action) {
		action.execute(generator)
	}

	def debugger(Action<DebuggerConfig> action) {
		action.execute(debugger)
	}

	def validator(Action<ValidatorConfig> action) {
		action.execute(validator)
	}

	def preferences(Map<String, String> preferences) {
		this.preferences.putAll(preferences)
	}
}

@Accessors
class GeneratorConfig {
	@Input boolean suppressWarningsAnnotation = true
	@Input @Optional String javaSourceLevel
	@Nested val GeneratedAnnotationOptions generatedAnnotation
	@Nested val NamedDomainObjectContainer<Outlet> outlets

	new(Project project, Language language) {
		this.generatedAnnotation = project.instantiate(typeof(GeneratedAnnotationOptions))
		this.outlets = project.container(Outlet)[outlet|project.instantiate(typeof(Outlet), language, outlet)]
	}
	def outlets(Action<NamedDomainObjectContainer<Outlet>> action) {
		action.execute(outlets)
	}

	@Internal def getOutlet() {
		outlets.maybeCreate(Outlet.DEFAULT_OUTLET)
	}

	def outlet(Action<Outlet> action) {
		action.execute(outlet)
	}
	def generatedAnnotation(Action<GeneratedAnnotationOptions> action) {
		action.execute(generatedAnnotation)
	}
}

@Accessors
class GeneratedAnnotationOptions {
	@Input boolean active
	@Input boolean includeDate
	@Input @Optional String comment
}

@Accessors
class DebuggerConfig {
	@Input SourceInstaller sourceInstaller = SourceInstaller.NONE
	@Input boolean hideSyntheticVariables = true
}

@Accessors
class ValidatorConfig {
	@Input Map<String, IssueSeverity> severities = newLinkedHashMap

	def void error(String code) {
		severities.put(code, IssueSeverity.ERROR)
	}

	def void warning(String code) {
		severities.put(code, IssueSeverity.WARNING)
	}

	def void info(String code) {
		severities.put(code, IssueSeverity.INFO)
	}

	def void ignore(String code) {
		severities.put(code, IssueSeverity.IGNORE)
	}
}

@Accessors
class Outlet implements Named {
	public static val DEFAULT_OUTLET = "DEFAULT_OUTPUT"

	@Internal val Language language
	@Input val String name
	@Input boolean producesJava = false
	@Input boolean cleanAutomatically = false

	@Internal def getFolderFragment() {
		if (name == Outlet.DEFAULT_OUTLET) {
			""
		} else {
			CaseFormat.LOWER_UNDERSCORE.to(CaseFormat.UPPER_CAMEL, name)
		}
	}
}