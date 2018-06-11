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
import org.gradle.util.ConfigureUtil
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.protocol.IssueSeverity
import org.xtext.gradle.tasks.internal.DefaultXtextSourceDirectorySet
import java.util.Arrays

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

	def void forceXtextVersion(Configuration dependencies, ()=>String xtextVersion) {
		dependencies.resolutionStrategy.eachDependency [
			if (requested.group == "org.eclipse.xtext" || requested.group == "org.eclipse.xtend")
				useVersion(xtextVersion.apply)
		]
	}

	def void makeXtextCompatible(Configuration dependencies) {
		dependencies.exclude(#{'group' -> 'asm'})
		dependencies.resolutionStrategy.eachDependency [
			if (requested.group == "com.google.inject" && requested.name == "guice")
				useVersion("4.0")
		]
	}
}

@Accessors
class Language implements Named {
	val String name
	String qualifiedName
	/** @deprecated use 'fileExtensions' instead */ @Deprecated String fileExtension
	String fileExtensions
	String setup
	val GeneratorConfig generator
	val debugger = new DebuggerConfig
	val validator = new ValidatorConfig
	Map<String, Object> preferences = newHashMap

	@Accessors(NONE) val Project project

	new(String name, Project project) {
		this.name = name
		this.project = project
		this.generator = new GeneratorConfig(project, this)
	}

	def getQualifiedName() {
		qualifiedName ?: setup.replace("StandaloneSetup", "")
	}

	def getFileExtensions() {
		if (fileExtensions === null) {
			Arrays.asList(fileExtension ?: name)
		} else {
			Arrays.asList(fileExtensions.split(','))
		}
	}

	def generator(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, generator)
	}

	def debugger(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, debugger)
	}

	def validator(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, validator)
	}

	def preferences(Map<String, String> preferences) {
		this.preferences.putAll(preferences)
	}
}

@Accessors
class GeneratorConfig {
	boolean suppressWarningsAnnotation = true
	String javaSourceLevel
	val GeneratedAnnotationOptions generatedAnnotation = new GeneratedAnnotationOptions
	val NamedDomainObjectContainer<Outlet> outlets

	new(Project project, Language language) {
		this.outlets = project.container(Outlet)[outlet|new Outlet(language, outlet)]
	}

	def outlets(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, outlets)
	}

	def getOutlet() {
		outlets.maybeCreate(Outlet.DEFAULT_OUTLET)
	}

	def outlet(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, outlet)
	}

	def generatedAnnotation(Closure<?> configureClosure) {
		ConfigureUtil.configure(configureClosure, generatedAnnotation)
	}
}

@Accessors
class GeneratedAnnotationOptions {
	boolean active
	boolean includeDate
	String comment
}

@Accessors
class DebuggerConfig {
	SourceInstaller sourceInstaller = SourceInstaller.NONE
	boolean hideSyntheticVariables = true
}

@Accessors
class ValidatorConfig {
	Map<String, IssueSeverity> severities = newHashMap

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

	val Language language
	val String name
	boolean producesJava = false
	boolean cleanAutomatically = false

	def getFolderFragment() {
		if (name == Outlet.DEFAULT_OUTLET) {
			""
		} else {
			CaseFormat.LOWER_UNDERSCORE.to(CaseFormat.UPPER_CAMEL, name)
		}
	}
}