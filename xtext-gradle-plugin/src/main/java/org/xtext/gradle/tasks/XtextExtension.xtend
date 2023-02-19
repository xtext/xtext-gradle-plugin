package org.xtext.gradle.tasks;

import com.google.common.base.CaseFormat
import java.io.File
import java.util.Map
import java.util.regex.Pattern
import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Action
import org.gradle.api.Named
import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.file.FileCollection
import org.gradle.api.model.ObjectFactory
import org.gradle.api.provider.MapProperty
import org.gradle.api.provider.Property
import org.gradle.api.provider.SetProperty
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.Nested
import org.gradle.api.tasks.Optional
import org.xtext.gradle.protocol.IssueSeverity
import org.xtext.gradle.tasks.internal.DefaultXtextSourceDirectorySet

abstract class XtextExtension {
	static val LIB_PATTERN = Pattern.compile("org\\.eclipse\\.xtext(\\.xbase\\.lib.*?)?-(.*)\\.jar")

	abstract def Property<String> getVersion()

	@Accessors val NamedDomainObjectContainer<XtextSourceDirectorySet> sourceSets

	abstract def NamedDomainObjectContainer<Language> getLanguages();

	@Inject
	new(ObjectFactory factory) {
		sourceSets = factory.domainObjectContainer(XtextSourceDirectorySet) [ name |
			factory.newInstance(DefaultXtextSourceDirectorySet, name, this)
		]
	}

	def sourceSets(Action<? super NamedDomainObjectContainer<XtextSourceDirectorySet>> configureAction) {
		configureAction.execute(sourceSets)
	}

	def languages(Action<? super NamedDomainObjectContainer<Language>> configureAction) {
		configureAction.execute(languages)
	}

	def String getXtextVersion(FileCollection classpath) {
		val version = version.orNull
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
}

abstract class Language implements Named {
	
	@Input abstract override String getName()
	
	@Input abstract def Property<String> getQualifiedName()

	@Input abstract def SetProperty<String> getFileExtensions()

	@Input abstract def Property<String> getSetup()

	@Nested abstract def GeneratorConfig getGenerator()

	@Nested abstract def DebuggerConfig getDebugger()

	@Nested abstract def ValidatorConfig getValidator()

	@Input abstract def MapProperty<String, Object> getPreferences()


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

abstract class GeneratorConfig {
	@Input abstract def Property<Boolean> getSuppressWarningsAnnotation()
	@Input @Optional abstract def Property<String> getJavaSourceLevel();
	@Nested abstract def GeneratedAnnotationOptions getGeneratedAnnotation()
	@Nested abstract def NamedDomainObjectContainer<Outlet> getOutlets()
	
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

abstract class GeneratedAnnotationOptions {
	@Input abstract def Property<Boolean> getActive()
	@Input abstract def Property<Boolean> getIncludeDate()
	@Input @Optional abstract def Property<String> getComment()
}

abstract class DebuggerConfig {
	@Input abstract def Property<String> getSourceInstaller()
	@Input abstract def Property<Boolean> getHideSyntheticVariables()
}

abstract class ValidatorConfig {
	@Input abstract def MapProperty<String, IssueSeverity> getSeverities()

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

abstract class Outlet implements Named {
	public static val DEFAULT_OUTLET = "DEFAULT_OUTPUT"

	@Input abstract override String getName()
	@Input abstract def Property<Boolean>  getProducesJava()
	@Input abstract def Property<Boolean>  getCleanAutomatically()

	@Internal def getFolderFragment() {
		if (name == Outlet.DEFAULT_OUTLET) {
			""
		} else {
			CaseFormat.LOWER_UNDERSCORE.to(CaseFormat.UPPER_CAMEL, name)
		}
	}
}
