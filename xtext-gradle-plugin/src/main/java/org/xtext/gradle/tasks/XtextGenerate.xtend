package org.xtext.gradle.tasks;

import com.google.common.base.Charsets
import com.google.common.io.Files
import com.google.common.io.Resources
import java.io.File
import java.util.Collection
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.JavaVersion
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.Classpath
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.Nested
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputDirectories
import org.gradle.api.tasks.SkipWhenEmpty
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.incremental.IncrementalTaskInputs
import org.xtext.gradle.XtextBuilderPlugin
import org.xtext.gradle.protocol.GradleBuildRequest
import org.xtext.gradle.protocol.GradleGeneratorConfig
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.GradleSourceInstallerConfig
import org.xtext.gradle.protocol.GradleOutputConfig
import org.xtext.gradle.protocol.IncrementalXtextBuilder
import org.xtext.gradle.tasks.internal.IncrementalXtextBuilderProvider

import static extension org.xtext.gradle.GradleExtensions.*

class XtextGenerate extends DefaultTask {

	static val builderJar = {
		val jar = File.createTempFile("xtext-gradle-builder", "jar")
		jar.deleteOnExit
		Resources.asByteSource(typeof(XtextBuilderPlugin).classLoader.getResource("xtext-gradle-builder.jar"))
			.copyTo(Files.asByteSink(jar))
		jar
	}

	@Accessors @Internal XtextSourceDirectorySet sources

	@Accessors @Nested Set<Language> languages

	@Accessors @Classpath FileCollection xtextClasspath

	@Accessors @Classpath @Optional FileCollection classpath

	@Accessors @Classpath @Optional FileCollection bootstrapClasspath

	@Accessors @Internal XtextSourceSetOutputs sourceSetOutputs

	@Accessors @Nested val XtextBuilderOptions options = project.instantiate(XtextBuilderOptions)

	IncrementalXtextBuilder builder

	Collection<File> generatedFiles

	@InputFiles
	def getAllSources() {
		sources.files
	}

	@InputFiles @SkipWhenEmpty
	def getMainSources() {
		val extensions = languages.filter[!generator.outlets.empty].map[fileExtensions].flatten.map["**/*." + it]
		sources.files.matching[include(extensions)]
	}

	@OutputDirectories
	def getOutputDirectories() {
		languages.filter[generator.outlets.exists[cleanAutomatically == true]].map [
			sourceSetOutputs.getDir(generator.outlet)
		].filterNull
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
			it.bootstrapClasspath = getBootstrapClasspath
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
			sourceInstallerByFileExtension = newLinkedHashMap

			languages.forEach[lang|
				lang.fileExtensions.forEach[ext |
					sourceInstallerByFileExtension.put(ext, new GradleSourceInstallerConfig() => [
						sourceInstaller = lang.debugger.sourceInstaller
						hideSyntheticVariables = lang.debugger.hideSyntheticVariables
					])
				]

			]
		]
		builder.installDebugInfo(request)
	}

	private def initializeBuilder() {
		builder = IncrementalXtextBuilderProvider.getBuilder(languageSetups, nullSafeEncoding, (getXtextClasspath.files + #[builderJar]).toSet)
	}

	private def getContainerHandle() {
		project.projectDir + ':' + sources.name
	}

	private def getNullSafeClasspath() {
		getClasspath ?: project.files
	}

	private def getNullSafeEncoding() {
		options.encoding ?: Charsets.UTF_8.name //TODO probably should be default charset
	}

	private def getLanguageSetups() {
		languages.map[setup].toSet
	}
}
