package org.xtext.gradle.tasks;

import com.google.inject.Guice
import java.net.URLClassLoader
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.builder.standalone.StandaloneBuilderModule
import org.eclipse.xtext.builder.standalone.incremental.BuildRequest
import org.eclipse.xtext.builder.standalone.incremental.IncrementalBuilder
import org.eclipse.xtext.builder.standalone.incremental.IndexState
import org.eclipse.xtext.generator.OutputConfigurationAdapter
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputDirectories
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.incremental.IncrementalTaskInputs
import org.gradle.internal.classloader.FilteringClassLoader

import static extension org.eclipse.xtext.builder.standalone.incremental.FilesAndURIs.*
import org.eclipse.xtext.workspace.WorkspaceConfigAdapter

class XtextGenerate extends DefaultTask {
	
	static IndexState previousIndexState = new IndexState
	static ClassLoader loader

	private XtextExtension xtext

	@Accessors @InputFiles FileCollection xtextClasspath

	@Accessors @InputFiles FileCollection classpath
	
	@InputFiles
	def getInputFiles() {
		val fileExtensions = xtext.languages.map[fileExtension].toSet
		xtext.sources.filter[fileExtensions.contains(asURI.fileExtension)]
	}
	
	@OutputDirectories
	def getOutputDirectories() {
		xtext.languages.map[outputs.map[project.file(dir)]].flatten
	}

	def configure(XtextExtension xtext) {
		this.xtext = xtext
	}

	@TaskAction
	def generate(IncrementalTaskInputs inputs) {
		loader = loader ?: new URLClassLoader(xtextClasspath.map[toURL], class.classLoader)
		val removedFiles = newArrayList
		val outOfDateFiles = newArrayList
		if (inputs.incremental) {
			inputs.outOfDate[outOfDateFiles += file]
			inputs.removed[removedFiles += file]
		} else {
			outOfDateFiles += inputFiles
		}
		if (outOfDateFiles.isEmpty && removedFiles.isEmpty) {
			return
		}
		val buildRequest = new BuildRequest => [
			baseDir = project.projectDir.asURI
			classPath = classpath.map[asURI].toList
			resourceSet = new XtextResourceSet => [
				eAdapters += new OutputConfigurationAdapter(
					xtext.languages.toMap[name].mapValues[
						outputs.map[output|
							new org.eclipse.xtext.generator.OutputConfiguration(output.name) => [
								outputDirectory = project.relativePath(output.dir)
							]
						].toSet
					]
				)
				eAdapters += new WorkspaceConfigAdapter(
					new GradleWorkspaceConfig(project)
				)
				classpathURIContext = new URLClassLoader(classpath.map[toURL])
			]
			previousState = previousIndexState
			deletedFiles = removedFiles.map[asURI].toList
			dirtyFiles = outOfDateFiles.map[asURI].toList
		]
		xtext.languages.forEach[
			val standaloneSetup = loader.loadClass(setup).newInstance as ISetup
			standaloneSetup.createInjectorAndDoEMFRegistration
		]
		val injector = Guice.createInjector(new StandaloneBuilderModule)
		val builder = injector.getInstance(IncrementalBuilder)
		val result = builder.build(buildRequest, IResourceServiceProvider.Registry.INSTANCE)
		previousIndexState = result.indexState
	}

	def generate(List<String> arguments) {
		System.setProperty("org.eclipse.emf.common.util.ReferenceClearingQueue", "false")
		val contextClassLoader = Thread.currentThread.contextClassLoader
		val classLoader = getCompilerClassLoader(getXtextClasspath)
		try {
			Thread.currentThread.contextClassLoader = classLoader
			val main = classLoader.loadClass("org.xtext.builder.standalone.Main")
			val method = main.getMethod("generate", typeof(String[]))
			val success = method.invoke(null, #[arguments as String[]]) as Boolean
			if (!success) {
				throw new GradleException('''Xtext generation failed''');
			}
		} finally {
			Thread.currentThread.contextClassLoader = contextClassLoader
		}
	}

	static val currentCompilerClassLoader = new ThreadLocal<URLClassLoader>() {
		override protected initialValue() {
			null
		}
	}

	private def getCompilerClassLoader(FileCollection classpath) {
		val classPathWithoutLog4j = classpath.filter[!name.contains("log4j")]
		val urls = classPathWithoutLog4j.map[absoluteFile.toURI.toURL].toList
		val currentClassLoader = currentCompilerClassLoader.get
		if (currentClassLoader !== null && currentClassLoader.URLs.toList == urls) {
			return currentClassLoader
		} else {
			val newClassLoader = new URLClassLoader(urls, loggingBridgeClassLoader)
			currentCompilerClassLoader.set(newClassLoader)
			return newClassLoader
		}
	}

	private def loggingBridgeClassLoader() {
		new FilteringClassLoader(XtextGenerate.classLoader) => [
			allowPackage("org.slf4j")
			allowPackage("org.apache.log4j")
		]
	}
}
