package org.xtext.gradle.tasks;

import com.google.common.base.Charsets
import com.google.inject.Guice
import java.net.URLClassLoader
import org.eclipse.emf.common.util.URI
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.builder.standalone.StandaloneBuilderModule
import org.eclipse.xtext.builder.standalone.incremental.BuildRequest
import org.eclipse.xtext.builder.standalone.incremental.BuildRequest.IPostValidationCallback
import org.eclipse.xtext.builder.standalone.incremental.IncrementalBuilder
import org.eclipse.xtext.builder.standalone.incremental.IndexState
import org.eclipse.xtext.generator.OutputConfigurationAdapter
import org.eclipse.xtext.parser.IEncodingProvider
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.validation.Issue
import org.eclipse.xtext.workspace.WorkspaceConfigAdapter
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputDirectories
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.incremental.IncrementalTaskInputs

import static org.xtext.gradle.tasks.XtextGenerate.*

import static extension org.eclipse.xtext.builder.standalone.incremental.FilesAndURIs.*

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
			afterValidate = validator
		]
		xtext.languages.forEach[
			val standaloneSetup = loader.loadClass(setup).newInstance as ISetup
			val injector = standaloneSetup.createInjectorAndDoEMFRegistration
			//FIXME we want to get rid of all stateful singletons
			injector.getInstance(IEncodingProvider.Runtime).defaultEncoding = Charsets.UTF_8.name
		]
		val injector = Guice.createInjector(new StandaloneBuilderModule)
		val builder = injector.getInstance(IncrementalBuilder)
		val result = builder.build(buildRequest, IResourceServiceProvider.Registry.INSTANCE)
		if (!validator.errorFree) {
			throw new GradleException("Xtext validation failed, see build log for details.")
		}
		previousIndexState = result.indexState
	}
}
