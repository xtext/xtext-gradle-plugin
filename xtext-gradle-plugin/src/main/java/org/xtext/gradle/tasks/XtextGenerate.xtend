package org.xtext.gradle.tasks;

import com.google.common.io.Files
import com.google.common.io.Resources
import java.io.File
import java.util.Collection
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.JavaVersion
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.tasks.Classpath
import org.gradle.api.tasks.IgnoreEmptyDirectories
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.Nested
import org.gradle.api.tasks.OutputDirectories
import org.gradle.api.tasks.SkipWhenEmpty
import org.gradle.api.tasks.TaskAction
import org.gradle.work.ChangeType
import org.gradle.work.Incremental
import org.gradle.work.InputChanges
import org.xtext.gradle.XtextBuilderPlugin
import org.xtext.gradle.protocol.GradleBuildRequest
import org.xtext.gradle.protocol.GradleGeneratorConfig
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.GradleSourceInstallerConfig
import org.xtext.gradle.protocol.GradleOutputConfig
import org.xtext.gradle.protocol.IncrementalXtextBuilder
import org.xtext.gradle.tasks.internal.IncrementalXtextBuilderProvider
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller

abstract class XtextGenerate extends DefaultTask {

	static val builderJar = {
		val jar = File.createTempFile("xtext-gradle-builder", "jar")
		jar.deleteOnExit
		Resources.asByteSource(typeof(XtextBuilderPlugin).classLoader.getResource("xtext-gradle-builder.jar")).copyTo(
			Files.asByteSink(jar))
		jar
	}

	@Accessors @Internal XtextSourceDirectorySet sources

	@Accessors @Nested Set<Language> languages

	@Accessors @Internal XtextSourceSetOutputs sourceSetOutputs

	IncrementalXtextBuilder builder

	Collection<File> generatedFiles

	@InputFiles
	@Incremental
	def getAllSources() {
		sources.files
	}

	@InputFiles
	@SkipWhenEmpty
	@IgnoreEmptyDirectories
	def getMainSources() {
		val extensions = languages.filter[!generator.outlets.empty].map[fileExtensions.get].flatten.map["**/*." + it]
		sources.files.matching[include(extensions)]
	}

	@OutputDirectories
	def getOutputDirectories() {
		languages.filter[generator.outlets.exists[cleanAutomatically.get == true]].map [
			sourceSetOutputs.getDir(generator.outlet)
		].filterNull
	}

	@TaskAction
	def generate(InputChanges inputs) {
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
			allFiles += allSources.files
			allClasspathEntries += this.classpath.files
			sourceFolders += sources.srcDirs
			generatorConfigsByLanguage += languages.toMap[qualifiedName.get].mapValues [
				val config = generator
				new GradleGeneratorConfig => [
					generateSyntheticSuppressWarnings = config.suppressWarningsAnnotation.get
					generateGeneratedAnnotation = config.generatedAnnotation.active.get
					includeDateInGeneratedAnnotation = config.generatedAnnotation.includeDate.get
					generatedAnnotationComment = config.generatedAnnotation.comment.orNull
					javaSourceLevel = JavaVersion.toVersion(config.javaSourceLevel.orNull ?:
						JavaVersion.current.majorVersion)
					outputConfigs = config.outlets.map [ outlet |
						new GradleOutputConfig => [
							outletName = outlet.name
							target = sourceSetOutputs.getDir(outlet)
							cleanAutomatically = outlet.cleanAutomatically.get
						]
					].toSet
				]
			]
			preferencesByLanguage += languages.toMap[qualifiedName.get].mapValues [
				val allPreferences = newHashMap
				allPreferences.putAll(preferences.get().mapValues[toString])
				allPreferences.putAll(validator.severities.get.mapValues[toString])
				allPreferences
			]
			it.logger = this.logger
		]
	}

	private def addIncrementalInputs(GradleBuildRequest request, InputChanges inputs) {
		request.incremental = options.incremental.get && inputs.incremental
		inputs.getFileChanges(allSources).forEach [
			if (changeType == ChangeType.REMOVED) {
				request.deletedFiles += file
			} else {
				request.dirtyFiles += file
			}
		]
		val classpathRoots = classpath.files
		inputs.getFileChanges(classpath)
			.forEach[change |
				if (change.normalizedPath.isEmpty) {
					request.dirtyClasspathEntries += change.file
				} else {
					val root = classpathRoots.findFirst[change.file.path.startsWith(it.path)]
					if (root !== null) {
						request.dirtyClasspathEntries += root
					} else {
						request.incremental = false
					}
				}
			]
	}

	def installDebugInfo(File classesDir) {
		if (mainSources.isEmpty) {
			return
		}
		initializeBuilder
		if (generatedFiles.isNullOrEmpty) {
			generatedFiles = getSourceSetOutputs.dirs.map [ dir |
				project.fileTree(dir)
			].flatten.toList
		}
		val request = new GradleInstallDebugInfoRequest => [
			generatedJavaFiles = generatedFiles.filter[name.endsWith(".java")].toSet
			it.classesDir = classesDir
			sourceInstallerByFileExtension = newLinkedHashMap

			languages.forEach [ lang |
				lang.fileExtensions.get.forEach [ ext |
					sourceInstallerByFileExtension.put(ext, new GradleSourceInstallerConfig() => [
						sourceInstaller = SourceInstaller.valueOf(lang.debugger.sourceInstaller.get)
						hideSyntheticVariables = lang.debugger.hideSyntheticVariables.get
					])
				]

			]
		]
		builder.installDebugInfo(request)
	}

	private def initializeBuilder() {
		builder = IncrementalXtextBuilderProvider.getBuilder(languageSetups, options.encoding.get,
			(getXtextClasspath.files + #[builderJar]).toSet)
	}

	private def getContainerHandle() {
		project.projectDir + ':' + sources.name
	}

	@Classpath
	@Incremental
	abstract def ConfigurableFileCollection getClasspath()

	@Classpath
	abstract def ConfigurableFileCollection getXtextClasspath()

	@Nested
	abstract def XtextBuilderOptions getOptions()

	private def getLanguageSetups() {
		languages.map[setup.get].toSet
	}
}
