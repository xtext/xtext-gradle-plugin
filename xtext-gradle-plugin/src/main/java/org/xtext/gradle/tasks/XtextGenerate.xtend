package org.xtext.gradle.tasks;

import java.io.File
import java.lang.reflect.InvocationTargetException
import java.net.URLClassLoader
import java.util.Collection
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.JavaVersion
import org.gradle.api.file.FileCollection
import org.gradle.api.file.SourceDirectorySet
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Nested
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputDirectories
import org.gradle.api.tasks.SkipWhenEmpty
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.incremental.IncrementalTaskInputs
import org.xtext.gradle.protocol.GradleBuildRequest
import org.xtext.gradle.protocol.GradleBuildResponse
import org.xtext.gradle.protocol.GradleGeneratorConfig
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.GradleSourceInstallerConfig
import org.xtext.gradle.protocol.GradleOutputConfig

class XtextGenerate extends DefaultTask {
	
	static Object builder

	@Accessors @InputFiles @SkipWhenEmpty SourceDirectorySet sources

	@Accessors @Nested Set<Language> languages

	@Accessors @InputFiles FileCollection xtextClasspath

	@Accessors @InputFiles @Optional FileCollection classpath

	@Accessors @Input @Optional String bootClasspath

	@Accessors @Input String encoding = "UTF-8"
	
	@Accessors @Input @Optional File classesDir

	@Accessors XtextSourceSetOutputs sourceSetOutputs
	
	Collection<File> generatedFiles
	
	@OutputDirectories
	def getOutputDirectories() {
		sourceSetOutputs.dirs
	}

	@TaskAction
	def generate(IncrementalTaskInputs inputs) {
		generatedFiles = newHashSet
		val builderUpToDate = isBuilderUpToDate

		val removedFiles = newArrayList
		val outOfDateFiles = newArrayList
		if (inputs.incremental && builderUpToDate) {
			inputs.outOfDate[outOfDateFiles += file]
			inputs.removed[removedFiles += file]
		} else {
			outOfDateFiles += sources
		}
		
		val outOfDateClasspathEntries = newHashSet
		outOfDateClasspathEntries.addAll(outOfDateFiles)
		outOfDateClasspathEntries.retainAll(classpath?.files ?: #{})
		if (!outOfDateClasspathEntries.isEmpty) {
			outOfDateFiles += sources
		}
		
		if (outOfDateFiles.isEmpty && removedFiles.isEmpty) {
			return
		}
		
		
		if (!builderUpToDate) {
			initializeBuilder
		}
		build(outOfDateFiles, removedFiles)
	}
	
	private def build(Collection<File> outOfDateFiles, Collection<File> removedFiles) {
		val request = new GradleBuildRequest => [
			projectName = project.name
			projectDir = project.projectDir
			containerHandle = project.path + ":" + sources.name
			dirtyFiles = outOfDateFiles
			deletedFiles = removedFiles
			classPath = classpath?.files ?: emptyList
			sourceFolders = sources.srcDirs
			generatorConfigsByLanguage = languages.toMap[qualifiedName].mapValues[
				val config = generator
				new GradleGeneratorConfig => [
					generateSyntheticSuppressWarnings = config.suppressWarningsAnnotation
					generateGeneratedAnnotation = config.generatedAnnotation.active
					includeDateInGeneratedAnnotation = config.generatedAnnotation.includeDate
					generatedAnnotationComment = config.generatedAnnotation.comment
					javaSourceLevel = JavaVersion.toVersion(config.javaSourceLevel)
					outputConfigs = config.outlets.map[outlet|
						new GradleOutputConfig => [
							outletName = outlet.name
							target = sourceSetOutputs.getDir(outlet)
						]
					].toSet
				]
			]
			preferencesByLanguage = languages.toMap[qualifiedName].mapValues[
				val allPreferences = newHashMap
				allPreferences.putAll(preferences.mapValues[toString])
				allPreferences.putAll(validator.severities.mapValues[toString])
				allPreferences
			]
			it.logger = this.logger
		]
		try {
			val response = builder.class.getMethod("build", GradleBuildRequest).invoke(builder, request) as GradleBuildResponse
			generatedFiles = response.generatedFiles
		} catch (InvocationTargetException e) {
			throw e.cause
		}
	}
	
	def installDebugInfo() {
		if (!builderUpToDate) {
			initializeBuilder
		}
		val request = new GradleInstallDebugInfoRequest => [
			generatedJavaFiles = generatedFiles.filter[name.endsWith(".java")].toSet
			it.classesDir = classesDir
			sourceInstallerByFileExtension = languages.toMap[fileExtension].mapValues[lang|
				new GradleSourceInstallerConfig() => [
					sourceInstaller = lang.debugger.sourceInstaller
					hideSyntheticVariables = lang.debugger.hideSyntheticVariables
				]
			]
		]
		try {
			builder.class.getMethod("installDebugInfo", GradleInstallDebugInfoRequest).invoke(builder, request)
		} catch (InvocationTargetException e) {
			throw e.cause
		}
	}
	
	private def initializeBuilder() {
		if (builder != null) {
			(builder.class.classLoader as URLClassLoader).close
		}
		val builderClass = builderClassLoader.loadClass("org.xtext.gradle.builder.XtextGradleBuilder")
		val builderConstructor = builderClass.getConstructor(String, Set, String)
		try {
			builder = builderConstructor.newInstance(project.rootDir.path, languageSetups, encoding)
		} catch (InvocationTargetException e) {
			throw e.cause
		}
	}
	
	private def isBuilderUpToDate() {
		if (builder === null) {
			return false
		}
		val oldClasspath = (builder.class.classLoader as URLClassLoader).URLs.toList
		val newClasspath = builderClassLoader.URLs.toList
		if (oldClasspath != newClasspath) {
			return false
		}
		val builderSetups = builder.class.getMethod("getLanguageSetups").invoke(builder)
		if (builderSetups != languageSetups) {
			return false
		}
		val builderEncoding = builder.class.getMethod("getEncoding").invoke(builder)
		if (builderEncoding != encoding) {
			return false
		}
		val builderOwner= builder.class.getMethod("getOwner").invoke(builder)
		if (builderOwner != project.rootDir.path) {
			return false
		}
		return true
	}
	
	private def getLanguageSetups() {
		languages.map[setup].toSet
	}
	
	private def getBuilderClassLoader() {
		//TODO parent filtering, we don't want asm etc.
		new URLClassLoader(xtextClasspath.map[toURL], class.classLoader)
	}
}
