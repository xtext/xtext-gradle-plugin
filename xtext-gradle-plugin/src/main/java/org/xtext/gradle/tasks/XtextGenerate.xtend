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
import org.gradle.api.tasks.util.PatternSet
import org.xtext.gradle.protocol.GradleBuildRequest
import org.xtext.gradle.protocol.GradleGeneratorConfig
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.GradleSourceInstallerConfig
import org.xtext.gradle.protocol.GradleOutputConfig
import org.xtext.gradle.protocol.IncrementalXtextBuilder
import org.xtext.gradle.tasks.internal.IncrementalXtextBuilderProvider

class XtextGenerate extends DefaultTask {


	@Accessors XtextSourceDirectorySet sources

	@Accessors Set<Language> languages

	@Accessors @InputFiles FileCollection xtextClasspath

	@Accessors @InputFiles @Optional FileCollection classpath

	@Accessors @Input @Optional FileCollection bootstrapClasspath

	@Accessors XtextSourceSetOutputs sourceSetOutputs

	@Accessors @Nested val XtextBuilderOptions options = new XtextBuilderOptions

	IncrementalXtextBuilder builder

	Collection<File> generatedFiles

	@InputFiles
	def getAllSources() {
		sources.files
	}

	@InputFiles @SkipWhenEmpty
	def getMainSources() {
		val patterns = new PatternSet
		languages.filter[!generator.outlets.empty].forEach [lang |
			patterns.include("**/*." + lang.fileExtension)
		]
		project.files(sources.srcDirs).asFileTree.matching(patterns)
	}

	@OutputDirectories
	def getOutputDirectories() {
		// filter out all output directories where the generating outlet has "cleanAutomatically == false"
		val buildContinuousLanguages = languages.filter[generator.outlets.exists[cleanAutomatically == true]]
		val result = newArrayList
		for (l : buildContinuousLanguages) {
			for (o : l.generator.outlets) {
				result.add(sourceSetOutputs.getDir(o))
			}
		}
		return result.filter[it !== null]
	}

	@TaskAction
	def generate(IncrementalTaskInputs inputs) {
		generatedFiles = newHashSet
		initializeBuilder

		val request = createBuildRequest
		addIncrementalInputs(request, inputs)
		val response = builder.build(request)
		generatedFiles = response.generatedFiles
	}

	private def createBuildRequest() {
		new GradleBuildRequest => [
			projectName = project.name
			projectDir = project.projectDir
			containerHandle = this.containerHandle
			allFiles = allSources.files
			allClasspathEntries = this.getNullSafeClasspath.files
			it.bootstrapClasspath = bootstrapClasspath
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
							cleanAutomatically = outlet.cleanAutomatically
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
	}

	private def addIncrementalInputs(GradleBuildRequest request, IncrementalTaskInputs inputs) {
		request.incremental = options.incremental && inputs.incremental

		inputs.outOfDate[
			if (allSources.contains(file)) {
				request.dirtyFiles += file
			}
			if (getNullSafeClasspath.contains(file)) {
				request.dirtyClasspathEntries += file
			}
		]

		inputs.removed[
			if (allSources.contains(file)) {
				request.deletedFiles += file
			}
		]
	}

	def installDebugInfo(File classesDir) {
		if (mainSources.isEmpty) {
			return
		}
		initializeBuilder
		if (generatedFiles.isNullOrEmpty) {
			generatedFiles = getSourceSetOutputs.dirs.map [dir |
				project.fileTree(dir)
			].flatten.toList
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
		builder.installDebugInfo(request)
	}

	private def initializeBuilder() {
		builder = IncrementalXtextBuilderProvider.getBuilder(languageSetups, nullSafeEncoding, xtextClasspath.files)
	}

	private def getContainerHandle() {
		project.projectDir + ':' + sources.name
	}

	private def getNullSafeClasspath() {
		classpath ?: project.files
	}

	private def getNullSafeEncoding() {
		options.encoding ?: Charsets.UTF_8.name //TODO probably should be default charset
	}

	private def getLanguageSetups() {
		languages.map[setup].toSet
	}
}
