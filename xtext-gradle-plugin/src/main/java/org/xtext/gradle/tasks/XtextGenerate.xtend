package org.xtext.gradle.tasks;

import com.google.inject.Guice
import java.net.URLClassLoader
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.emf.common.util.URI
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.builder.standalone.StandaloneBuilderModule
import org.eclipse.xtext.builder.standalone.incremental.BuildRequest
import org.eclipse.xtext.builder.standalone.incremental.BuildRequest.IPostValidationCallback
import org.eclipse.xtext.builder.standalone.incremental.ChunkedResourceDescriptions
import org.eclipse.xtext.builder.standalone.incremental.ContextualChunkedResourceDescriptions
import org.eclipse.xtext.builder.standalone.incremental.IncrementalBuilder
import org.eclipse.xtext.builder.standalone.incremental.IndexState
import org.eclipse.xtext.builder.standalone.incremental.Source2GeneratedMapping
import org.eclipse.xtext.generator.OutputConfigurationAdapter
import org.eclipse.xtext.java.JavaSourceLanguageSetup
import org.eclipse.xtext.parser.IEncodingProvider
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.validation.Issue
import org.eclipse.xtext.workspace.WorkspaceConfigAdapter
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputDirectories
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.incremental.IncrementalTaskInputs

import static org.xtext.gradle.tasks.XtextGenerate.*

import static extension org.eclipse.xtext.builder.standalone.incremental.FilesAndURIs.*
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData

class XtextGenerate extends DefaultTask {
	
	static val index = new ChunkedResourceDescriptions
	static val generatedMappings = new ConcurrentHashMap<String, Source2GeneratedMapping>
	
	static val incrementalbuilder = Guice.createInjector(new StandaloneBuilderModule).getInstance(IncrementalBuilder)
	static URLClassLoader languageClassLoader

	private XtextExtension xtext

	@Accessors @InputFiles FileCollection xtextClasspath

	@Accessors @InputFiles FileCollection classpath
	
	@Accessors @Input boolean useJava = false
	
	@InputFiles
	def getInputFiles() {
		val fileExtensions = xtext.languages.map[fileExtension].toSet
		xtext.sources.filter[fileExtensions.contains(asURI.fileExtension) || useJava && asURI.fileExtension == 'java']
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
		val removedFiles = newArrayList
		val outOfDateFiles = newArrayList
		if (inputs.incremental && !index.empty) {
			inputs.outOfDate[outOfDateFiles += file]
			inputs.removed[removedFiles += file]
		} else {
			outOfDateFiles += inputFiles
		}
		if (outOfDateFiles.isEmpty && removedFiles.isEmpty) {
			return
		}
		val validator = new IPostValidationCallback() {
			var errorFree = true
			
			override afterValidate(URI validated, Iterable<Issue> issues) {
				for (issue : issues) {
					switch (issue.severity) {
						case ERROR: {
							logger.error(issue.toString)
							errorFree = false
						}
						case WARNING:
							logger.warn(issue.toString)
						case INFO:
							logger.info(issue.toString)
						case IGNORE:
							logger.debug(issue.toString)
					}
				}
				return errorFree
			}
		}
		val buildRequest = new BuildRequest => [
			baseDir = project.projectDir.asURI
			
			val fileMappings = generatedMappings.get(project.path) ?: new Source2GeneratedMapping
			val indexChunk = index.getContainer(project.path) ?: new ResourceDescriptionsData(emptyList)
			
			previousState = new IndexState(indexChunk, fileMappings)
			newState = new IndexState(indexChunk.copy, fileMappings.copy)
			
			resourceSet = new XtextResourceSet => [
				eAdapters += new OutputConfigurationAdapter(
					xtext.languages.toMap[qualifiedName].mapValues[
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
			ResourceDescriptionsData.ResourceSetAdapter.installResourceDescriptionsData(resourceSet, newState.resourceDescriptions)
			new ContextualChunkedResourceDescriptions(index) => [descriptions|
				descriptions.setContainer(project.path, newState.resourceDescriptions)
				descriptions.context = resourceSet
				descriptions.attachToEmfObject(resourceSet)
			]
			
			deletedFiles = removedFiles.map[asURI].toList
			dirtyFiles = outOfDateFiles.map[asURI].toList
			afterValidate = validator
		]
		initializeLanguageClassLoader(inputs)
		val result = incrementalbuilder.build(buildRequest, IResourceServiceProvider.Registry.INSTANCE)
		if (!validator.errorFree) {
			throw new GradleException("Xtext validation failed, see build log for details.")
		}
		index.setContainer(project.path, result.indexState.resourceDescriptions)
		generatedMappings.put(project.path, result.indexState.fileMappings)
	}
	
	private def initializeLanguageClassLoader(IncrementalTaskInputs inputs) {
		if (languageClassLoaderNeedsUpdate(inputs)) {
			languageClassLoader = new URLClassLoader(xtextClasspath.map[toURL], class.classLoader)
			xtext.languages.forEach[
				val standaloneSetup = languageClassLoader.loadClass(setup).newInstance as ISetup
				val injector = standaloneSetup.createInjectorAndDoEMFRegistration
				injector.getInstance(IEncodingProvider.Runtime).defaultEncoding = xtext.encoding
			]
			if (useJava) {
				new JavaSourceLanguageSetup().createInjectorAndDoEMFRegistration
			}
		}
	}
	
	private def languageClassLoaderNeedsUpdate(IncrementalTaskInputs inputs) {
		languageClassLoader == null || languageClassLoader.URLs.toList != xtextClasspath.map[toURL].toList || !inputs.incremental
	}
}
