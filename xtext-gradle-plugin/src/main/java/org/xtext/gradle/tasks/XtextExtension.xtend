package org.xtext.gradle.tasks;

import com.google.common.base.CaseFormat
import com.google.common.collect.Lists
import groovy.lang.Closure
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
import org.gradle.util.ConfigureUtil
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.protocol.IssueSeverity
import org.xtext.gradle.tasks.internal.DefaultXtextSourceDirectorySet
import org.xtext.gradle.tasks.internal.Version

import static extension org.xtext.gradle.GradleExtensions.*

class XtextExtension {
	@Accessors String version
	@Accessors val NamedDomainObjectContainer<XtextSourceDirectorySet> sourceSets
	@Accessors val NamedDomainObjectContainer<Language> languages;
	@Accessors val List<XtextClasspathInferrer> classpathInferrers;

	Project project

	new(Project project) {
		this.project = project
		sourceSets = project.container(XtextSourceDirectorySet)[name|new DefaultXtextSourceDirectorySet(name, project, this)]
		languages = project.container(Language)[name|new Language(name, project)]
		classpathInferrers = Lists.newArrayList
	}

	def sourceSets(Action<? super NamedDomainObjectContainer<XtextSourceDirectorySet>> configureAction) {
		configureAction.execute(sourceSets)
	}

	def languages(Action<? super NamedDomainObjectContainer<Language>> configureAction) {
		configureAction.execute(languages)
	}

	static val LIB_PATTERN = Pattern.compile("org\\.eclipse\\.xtext\\..*-(\\d.*?).jar")

	def String getXtextVersion(FileCollection classpath) {
		if (version !== null)
			return version
		for (file : classpath) {
			val matcher = LIB_PATTERN.matcher(file.name)
			if (matcher.matches) {
				return matcher.group(1)
			}
		}
		return null
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
	@Input String fileExtension
	@Input String setup
	@Nested val GeneratorConfig generator
	@Nested val debugger = new DebuggerConfig
	@Nested val validator = new ValidatorConfig
	@Input Map<String, Object> preferences = newLinkedHashMap

	new(String name, Project project) {
		this.name = name
		this.generator = new GeneratorConfig(project, this)
	}

	def getQualifiedName() {
		qualifiedName ?: setup.replace("StandaloneSetup", "")
	}

	def getFileExtension() {
		fileExtension ?: name
	}

	def generator(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, generator)
	}

	def generator(Action<GeneratorConfig> action) {
		action.execute(generator)
	}

	def debugger(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, debugger)
	}

	def debugger(Action<DebuggerConfig> action) {
		action.execute(debugger)
	}

	def validator(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, validator)
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
	@Nested val GeneratedAnnotationOptions generatedAnnotation = new GeneratedAnnotationOptions
	@Nested val NamedDomainObjectContainer<Outlet> outlets

	new(Project project, Language language) {
		this.outlets = project.container(Outlet)[outlet|new Outlet(language, outlet)]
	}

	def outlets(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, outlets)
	}

	def outlets(Action<NamedDomainObjectContainer<Outlet>> action) {
		action.execute(outlets)
	}

	@Internal def getOutlet() {
		outlets.maybeCreate(Outlet.DEFAULT_OUTLET)
	}

	def outlet(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, outlet)
	}

	def outlet(Action<Outlet> action) {
		action.execute(outlet)
	}

	def generatedAnnotation(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, generatedAnnotation)
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