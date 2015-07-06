package org.xtext.gradle.tasks;

import java.io.File
import java.lang.reflect.InvocationTargetException
import java.net.URLClassLoader
import java.util.Collection
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputDirectories
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.incremental.IncrementalTaskInputs
import org.xtext.gradle.protocol.GradleBuildRequest
import org.xtext.gradle.protocol.GradleOutputConfig

class XtextGenerate extends DefaultTask {
	
	static Object builder

	@Accessors XtextExtension xtext

	@Accessors @InputFiles FileCollection xtextClasspath

	@Accessors @InputFiles FileCollection classpath
	
	@Accessors @Input boolean useJava = false
	
	@InputFiles
	def getInputFiles() {
		val fileExtensions = getFileExtensions
		xtext.sources.filter[fileExtensions.contains(name.split("\\.").last)]
	}
	
	@OutputDirectories
	def getOutputDirectories() {
		xtext.languages.map[outputs.map[project.file(dir)]].flatten
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
			classPath = classpath.files
			sourceFolders = xtext.sources.srcDirs
			outputConfigsPerLanguage = xtext.languages.toMap[qualifiedName].mapValues[
				outputs.map[output|
					new GradleOutputConfig => [
						outletName = output.name
						target = project.file(output.dir)
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
		builder = builderConstructor.newInstance(languageSetups, xtext.encoding)
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
		if (builderEncoding != xtext.encoding) {
			return false
		}
		return true
	}
	
	private def getLanguageSetups() {
		val setups = newHashSet
		setups += xtext.languages.map[setup]
		if (useJava) {
			setups += "org.eclipse.xtext.java.JavaSourceLanguageSetup"
		}
		setups
	}
	
	private def getFileExtensions() {
		val fileExtensions = newHashSet
		fileExtensions += xtext.languages.map[fileExtension]
		if (useJava) {
			fileExtensions += 'java'
		}
		fileExtensions
	}
	
	private def getBuilderClassLoader() {
		//TODO parent filtering, we don't want asm etc.
		new URLClassLoader(xtextClasspath.map[toURL], class.classLoader)
	}
}
