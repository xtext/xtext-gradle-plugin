package org.xtext.gradle.tasks;

import com.google.common.base.Charsets
import java.io.File
import java.util.Collection
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.JavaVersion
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Nested
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputDirectories
import org.gradle.api.tasks.SkipWhenEmpty
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.incremental.IncrementalTaskInputs
import org.xtext.gradle.protocol.GradleBuildRequest
import org.xtext.gradle.protocol.GradleGeneratorConfig
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.GradleSourceInstallerConfig
import org.xtext.gradle.protocol.GradleOutputConfig
import org.xtext.gradle.protocol.IncrementalXtextBuilder
import org.xtext.gradle.tasks.internal.IncrementalXtextBuilderProvider

class XtextGenerate extends DefaultTask {
	

	@Accessors XtextSourceDirectorySet sources

	@Accessors @Nested Set<Language> languages

	@Accessors @InputFiles FileCollection xtextClasspath

	@Accessors @InputFiles @Optional FileCollection classpath

	@Accessors @Input @Optional String bootClasspath
	
	@Accessors @Input @Optional File classesDir

	@Accessors XtextSourceSetOutputs sourceSetOutputs
	
	@Accessors @Nested val XtextBuilderOptions options = new XtextBuilderOptions
	
	IncrementalXtextBuilder builder
	
	Collection<File> generatedFiles
	
	@InputFiles @SkipWhenEmpty
	def getSources() {
		sources.files
	}
	
	def getNullSafeClasspath() {
		classpath ?: project.files
	}
	
	def getNullSafeEncoding() {
		options.encoding ?: Charsets.UTF_8.name //TODO probably should be default charset
	}
	
	@OutputDirectories
	def getOutputDirectories() {
		sourceSetOutputs.dirs
	}

	@TaskAction
	def generate(IncrementalTaskInputs inputs) {
		initializeBuilder
		generatedFiles = newHashSet

		val removedFiles = newLinkedHashSet
		val outOfDateFiles = newLinkedHashSet
		inputs.outOfDate[
			if (getSources.contains(file) || getNullSafeClasspath.contains(file)) {
				outOfDateFiles += file
			}
		]
		inputs.removed[
			if (getSources.contains(file)) {
				removedFiles += file
			}
		]
		
		if (needsCleanBuild) {
			outOfDateFiles += getSources
			outOfDateFiles += getNullSafeClasspath
		}
		
		//TODO should be replaced by incremental jar indexing
		val outOfDateClasspathEntries = newHashSet
		outOfDateClasspathEntries.addAll(outOfDateFiles)
		outOfDateClasspathEntries.retainAll(getNullSafeClasspath.files)
		if (!outOfDateClasspathEntries.isEmpty) {
			outOfDateFiles += getSources
		}
		
		if (outOfDateFiles.isEmpty && removedFiles.isEmpty) {
			return
		}
		
		build(outOfDateFiles, removedFiles)
	}
	
	private def build(Collection<File> outOfDateFiles, Collection<File> removedFiles) {
		val request = new GradleBuildRequest => [
			projectName = project.name
			projectDir = project.projectDir
			containerHandle = this.containerHandle
			dirtyFiles = outOfDateFiles
			deletedFiles = removedFiles
			classpath = this.getNullSafeClasspath.files
			it.bootClasspath = bootClasspath
			sourceFolders = sources.srcDirs
			generatorConfigsByLanguage = languages.toMap[qualifiedName].mapValues[
				val config = generator
				new GradleGeneratorConfig => [
					generateSyntheticSuppressWarnings = config.suppressWarningsAnnotation
					generateGeneratedAnnotation = config.generatedAnnotation.active
					includeDateInGeneratedAnnotation = config.generatedAnnotation.includeDate
					generatedAnnotationComment = config.generatedAnnotation.comment
					javaSourceLevel = JavaVersion.toVersion(config.javaSourceLevel ?: JavaVersion.current.majorVersion)
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
		val response = builder.build(request)
		generatedFiles = response.generatedFiles
	}
	
	private def getContainerHandle() {
		project.projectDir + ':' + sources.name
	}
	
	def installDebugInfo() {
		initializeBuilder
		val request = new GradleInstallDebugInfoRequest => [
			if (generatedFiles.isNullOrEmpty) {
				generatedFiles = newHashSet
				getSourceSetOutputs.dirs.forEach [
					generatedFiles += project.fileTree(it).files.filter[File f|
						f.name.endsWith(".java")
					]
				]
			}
			generatedJavaFiles = generatedFiles.filter[name.endsWith(".java")].toSet
			it.classesDir = classesDir
			sourceInstallerByFileExtension = languages.toMap[fileExtension].mapValues[lang|
				new GradleSourceInstallerConfig() => [
					sourceInstaller = lang.debugger.sourceInstaller
					hideSyntheticVariables = lang.debugger.hideSyntheticVariables
				]
			]
		]
		builder.installDebugInfo(request)
	}
	
	private def initializeBuilder() {
		builder = IncrementalXtextBuilderProvider.getBuilder(languageSetups, nullSafeEncoding, xtextClasspath.files)
	}
	
	private def needsCleanBuild() {
		!options.incremental || builder.needsCleanBuild(containerHandle)
	}
	
	private def getLanguageSetups() {
		languages.map[setup].toSet
	}
}
