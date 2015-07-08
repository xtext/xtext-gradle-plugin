package org.xtext.gradle.tasks;

import java.io.File
import java.lang.reflect.InvocationTargetException
import java.net.URLClassLoader
import java.util.Collection
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.file.FileCollection
import org.gradle.api.file.SourceDirectorySet
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Nested
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputDirectories
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.incremental.IncrementalTaskInputs
import org.xtext.gradle.protocol.GradleBuildRequest
import org.xtext.gradle.protocol.GradleOutputConfig

class XtextGenerate extends DefaultTask {
	
	static Object builder

	@Accessors SourceDirectorySet sources
	
	@Accessors XtextSourceSetOutputs sourceSetOutputs
	
	@Accessors @Nested Set<Language> languages

	@Accessors @InputFiles FileCollection xtextClasspath

	@Accessors @InputFiles @Optional FileCollection classpath
	
	@Accessors @Input @Optional String bootClasspath
	
	@Accessors @Input String encoding = "UTF-8"
	
	@InputFiles
	def getInputFiles() {
		val fileExtensions = getFileExtensions
		sources.filter[fileExtensions.contains(name.split("\\.").last)]
	}
	
	@OutputDirectories
	def getOutputDirectories() {
		sourceSetOutputs.dirs
	}

	@TaskAction
	def generate(IncrementalTaskInputs inputs) {
		val builderUpToDate = isBuilderUpToDate

		val removedFiles = newArrayList
		val outOfDateFiles = newArrayList
		if (inputs.incremental && builderUpToDate) {
			inputs.outOfDate[outOfDateFiles += file]
			inputs.removed[removedFiles += file]
		} else {
			outOfDateFiles += inputFiles
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
			project = this.project
			dirtyFiles = outOfDateFiles
			deletedFiles = removedFiles
			classPath = classpath?.files ?: emptyList
			sourceFolders = sources.srcDirs
			outputConfigsPerLanguage = languages
				.filter[sourceSetOutputs.findByName(name) != null]
				.toMap[qualifiedName].mapValues[
					sourceSetOutputs.findByName(name).map[output|
						new GradleOutputConfig => [
							outletName = output.name
							target = output.dir
						]
					].toSet
				]
		]
		try {
			builder.class.getMethod("build", GradleBuildRequest).invoke(builder, request)
		} catch (InvocationTargetException e) {
			throw e.cause
		}
	}
	
	private def initializeBuilder() {
		if (builder != null) {
			(builder.class.classLoader as URLClassLoader).close
		}
		val builderClass = builderClassLoader.loadClass("org.xtext.builder.standalone.XtextGradleBuilder")
		val builderConstructor = builderClass.getConstructor(Set, String)
		builder = builderConstructor.newInstance(languageSetups, encoding)
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
		return true
	}
	
	private def getLanguageSetups() {
		languages.map[setup].toSet
	}
	
	private def getFileExtensions() {
		languages.map[fileExtension].toSet
	}
	
	private def getBuilderClassLoader() {
		//TODO parent filtering, we don't want asm etc.
		new URLClassLoader(xtextClasspath.map[toURL], class.classLoader)
	}
}
