package org.xtext.gradle.builder

import com.google.inject.Guice
import java.io.File
import java.net.URLClassLoader
import java.util.Set
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.emf.common.util.URI
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IncrementalBuilder
import org.eclipse.xtext.build.IndexState
import org.eclipse.xtext.build.Source2GeneratedMapping
import org.eclipse.xtext.generator.OutputConfiguration
import org.eclipse.xtext.generator.OutputConfigurationAdapter
import org.eclipse.xtext.parser.IEncodingProvider
import org.eclipse.xtext.preferences.MapBasedPreferenceValues
import org.eclipse.xtext.preferences.PreferenceValuesByLanguage
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ChunkedResourceDescriptions
import org.eclipse.xtext.resource.impl.ProjectDescription
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.eclipse.xtext.workspace.WorkspaceConfigAdapter
import org.eclipse.xtext.xbase.compiler.GeneratorConfig
import org.eclipse.xtext.xbase.compiler.GeneratorConfigProvider
import org.eclipse.xtext.xbase.compiler.JavaVersion
import org.gradle.api.GradleException
import org.xtext.gradle.builder.InstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.builder.InstallDebugInfoRequest.SourceInstallerConfig
import org.xtext.gradle.protocol.GradleBuildRequest
import org.xtext.gradle.protocol.GradleBuildResponse
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest

import static org.eclipse.xtext.util.UriUtil.createFolderURI

class XtextGradleBuilder {
	val index = new ChunkedResourceDescriptions
	val generatedMappings = new ConcurrentHashMap<String, Source2GeneratedMapping>
	val sharedInjector = Guice.createInjector
	val incrementalbuilder = sharedInjector.getInstance(IncrementalBuilder)
	val debugInfoInstaller = sharedInjector.getInstance(DebugInfoInstaller)
	
	@Accessors
	val String owner
	@Accessors
	val Set<String> languageSetups
	@Accessors
	val String encoding

	new(String owner, Set<String> setupNames, String encoding) throws Exception {
		System.setProperty("org.eclipse.emf.common.util.ReferenceClearingQueue", "false")
		for (setupName : setupNames) {
			val setupClass = class.classLoader.loadClass(setupName)
			val setup = setupClass.newInstance as ISetup
			val injector = setup.createInjectorAndDoEMFRegistration
			injector.getInstance(IEncodingProvider.Runtime).setDefaultEncoding(encoding)
		}
		this.owner = owner
		this.languageSetups = setupNames
		this.encoding = encoding
	}

	def GradleBuildResponse build(GradleBuildRequest gradleRequest) {
		val containerHandle = gradleRequest.containerHandle
		val jvmTypesLoader = gradleRequest.jvmTypesLoader
		val validator = new GradleValidatonCallback(gradleRequest.logger)
		val response = new GradleBuildResponse
		
		val request = new BuildRequest => [
			baseDir = createFolderURI(gradleRequest.projectDir)
			dirtyFiles = gradleRequest.dirtyFiles.map[URI.createFileURI(absolutePath)].toList
			deletedFiles = gradleRequest.deletedFiles.map[URI.createFileURI(absolutePath)].toList
			
			val indexChunk = index.getContainer(containerHandle)?.copy ?: new ResourceDescriptionsData(emptyList)
			val fileMappings = generatedMappings.get(containerHandle)?.copy ?: new Source2GeneratedMapping
			state = new IndexState(indexChunk, fileMappings)

			afterValidate = validator
			afterGenerateFile = [source, target| response.generatedFiles.add(new File(target.toFileString))]
			
			resourceSet = sharedInjector.getInstance(XtextResourceSet) => [
				classpathURIContext = jvmTypesLoader
				attachWorkspaceConfig(gradleRequest)
				attachGeneratorConfig(gradleRequest)
				attachOutputConfig(gradleRequest)
				attachPreferences(gradleRequest)
				attachProjectDescription(containerHandle, it)
				val contextualIndex = index.createShallowCopyWith(it)
				contextualIndex.setContainer(containerHandle, indexChunk)
			]
		]
		
		val registry = IResourceServiceProvider.Registry.INSTANCE
		val result = try {
			incrementalbuilder.build(request, [uri| registry.getResourceServiceProvider(uri)])
		} finally {
			cleanup(gradleRequest, request)
		}
		
		if (!validator.isErrorFree) {
			throw new GradleException("Xtext validation failed, see build log for details.")
		}
		
		val resultingIndex = result.indexState
		index.setContainer(containerHandle, resultingIndex.resourceDescriptions)
		generatedMappings.put(containerHandle, resultingIndex.fileMappings)
		return response
	}
	
	def getJvmTypesLoader(GradleBuildRequest gradleRequest) {
		val parent = if (gradleRequest.bootClasspath === null) {
			ClassLoader.systemClassLoader
		} else {
			new AlternateJdkLoader(gradleRequest.bootClasspath.split(File.pathSeparator).map[new File(it)])
		}
		new URLClassLoader(gradleRequest.classpath.map[toURI.toURL], parent)
	}
	
	private def cleanup(GradleBuildRequest gradleRequest, BuildRequest request) {
		val resourceSet = request.resourceSet
		val jvmTypesLoader = resourceSet.classpathURIContext as URLClassLoader
		try {
			jvmTypesLoader.close
		} catch (Exception e) {
			gradleRequest.logger.debug("Couldn't close jvm types classloader", e)
		}
		resourceSet.resources.clear
		resourceSet.eAdapters.clear
	}
	
	private def attachWorkspaceConfig(XtextResourceSet resourceSet, GradleBuildRequest gradleRequest) {
		resourceSet.eAdapters += new WorkspaceConfigAdapter(new GradleWorkspaceConfig(gradleRequest))
	}
	
	private def attachProjectDescription(String containerHandle, XtextResourceSet resourceSet) {
		new ProjectDescription => [
			name = containerHandle
			//TODO dependencies
			attachToEmfObject(resourceSet)
		]
	}
	
	private def attachGeneratorConfig(XtextResourceSet resourceSet, GradleBuildRequest gradleRequest) {
		new GeneratorConfigProvider.GeneratorConfigAdapter => [
			attachToEmfObject(resourceSet)
			language2GeneratorConfig.putAll(
				gradleRequest.generatorConfigsByLanguage.mapValues[gradleConfig|
					new GeneratorConfig => [
						generateSyntheticSuppressWarnings = gradleConfig.isGenerateSyntheticSuppressWarnings
						generateGeneratedAnnotation = gradleConfig.isGenerateGeneratedAnnotation
						includeDateInGeneratedAnnotation = 	gradleConfig.isIncludeDateInGeneratedAnnotation
						generatedAnnotationComment = gradleConfig.generatedAnnotationComment
						javaSourceVersion = JavaVersion.fromQualifier(gradleConfig.javaSourceLevel.toString)
					]
				]
			)
		]
	}

	private def attachOutputConfig(XtextResourceSet resourceSet, GradleBuildRequest gradleRequest) {
		resourceSet.eAdapters += new OutputConfigurationAdapter(
			gradleRequest.generatorConfigsByLanguage.mapValues[
				outputConfigs.map[gradleOutputConfig|
					new OutputConfiguration(gradleOutputConfig.outletName) => [
						outputDirectory = URI.createFileURI(gradleOutputConfig.target.absolutePath).toString
					]
				].toSet
			]
		)
	}

	private def attachPreferences(XtextResourceSet resourceSet, GradleBuildRequest gradleRequest) {
		new PreferenceValuesByLanguage => [
			attachToEmfObject(resourceSet)
			for (entry : gradleRequest.preferencesByLanguage.entrySet) {
				put(entry.key, new MapBasedPreferenceValues(entry.value))
			}
		]
	}
	
	def void installDebugInfo(GradleInstallDebugInfoRequest gradleRequest) {
		val request = new InstallDebugInfoRequest => [
			classesDir = gradleRequest.classesDir
			outputDir =gradleRequest.classesDir
			sourceInstallerByFileExtension = gradleRequest.sourceInstallerByFileExtension.mapValues[gradleConfig|
				new SourceInstallerConfig => [
					sourceInstaller = SourceInstaller.valueOf(gradleConfig.sourceInstaller.name)
					hideSyntheticVariables = gradleConfig.isHideSyntheticVariables
				]
			]
			generatedJavaFiles = gradleRequest.generatedJavaFiles
			resourceSet = sharedInjector.getInstance(XtextResourceSet) => [
				classpathURIContext = ClassLoader.systemClassLoader
				new ChunkedResourceDescriptions(emptyMap, it)
			]
		]
		debugInfoInstaller.installDebugInfo(request)
	}
}
