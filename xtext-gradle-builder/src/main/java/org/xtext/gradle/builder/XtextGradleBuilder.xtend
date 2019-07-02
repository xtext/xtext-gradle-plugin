package org.xtext.gradle.builder

import com.google.common.hash.Funnels
import com.google.common.hash.HashCode
import com.google.common.hash.Hasher
import com.google.common.hash.Hashing
import com.google.common.io.Files
import com.google.inject.Guice
import java.io.Closeable
import java.io.File
import java.net.URLClassLoader
import java.util.List
import java.util.Set
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IncrementalBuilder
import org.eclipse.xtext.build.IndexState
import org.eclipse.xtext.build.Source2GeneratedMapping
import org.eclipse.xtext.generator.OutputConfiguration
import org.eclipse.xtext.generator.OutputConfigurationAdapter
import org.eclipse.xtext.mwe.PathTraverser
import org.eclipse.xtext.parser.IEncodingProvider
import org.eclipse.xtext.preferences.MapBasedPreferenceValues
import org.eclipse.xtext.preferences.PreferenceValuesByLanguage
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ChunkedResourceDescriptions
import org.eclipse.xtext.resource.impl.ProjectDescription
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.eclipse.xtext.util.JavaVersion
import org.eclipse.xtext.util.internal.AlternateJdkLoader
import org.eclipse.xtext.workspace.ProjectConfigAdapter
import org.eclipse.xtext.xbase.compiler.GeneratorConfig
import org.eclipse.xtext.xbase.compiler.GeneratorConfigProvider
import org.gradle.api.GradleException
import org.xtext.gradle.builder.InstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.builder.InstallDebugInfoRequest.SourceInstallerConfig
import org.xtext.gradle.protocol.GradleBuildRequest
import org.xtext.gradle.protocol.GradleBuildResponse
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest
import org.xtext.gradle.protocol.IncrementalXtextBuilder

import static org.eclipse.xtext.util.UriUtil.createFolderURI

class XtextGradleBuilder implements IncrementalXtextBuilder {
	val index = new GradleResourceDescriptions
	val dependencyHashes = new ConcurrentHashMap<File, HashCode>
	val generatedMappings = new ConcurrentHashMap<String, Source2GeneratedMapping>
	val sharedInjector = Guice.createInjector
	val incrementalbuilder = sharedInjector.getInstance(IncrementalBuilder)
	val debugInfoInstaller = sharedInjector.getInstance(DebugInfoInstaller)
	
	new(Set<String> setupNames, String encoding) throws Exception {
		System.setProperty("org.eclipse.emf.common.util.ReferenceClearingQueue", "false")
		for (setupName : setupNames) {
			val setupClass = class.classLoader.loadClass(setupName)
			val setup = setupClass.newInstance as ISetup
			val injector = setup.createInjectorAndDoEMFRegistration
			injector.getInstance(IEncodingProvider.Runtime).setDefaultEncoding(encoding)
		}
	}

	override GradleBuildResponse build(GradleBuildRequest gradleRequest) {
		val containerHandle = gradleRequest.containerHandle
		val validator = new GradleValidatonCallback(gradleRequest.logger)
		val response = new GradleBuildResponse
		
		indexChangedClasspathEntries(gradleRequest)
		
		val request = new BuildRequest => [
			baseDir = createFolderURI(gradleRequest.projectDir)
			if (needsCleanBuild(gradleRequest)) {
				dirtyFiles = gradleRequest.allFiles.map[URI.createFileURI(absolutePath)].toList
				state = new IndexState
			} else {
				dirtyFiles = gradleRequest.dirtyFiles.map[URI.createFileURI(absolutePath)].toList
				deletedFiles = gradleRequest.deletedFiles.map[URI.createFileURI(absolutePath)].toList
				val indexChunk = index.getContainer(containerHandle)?.copy ?: new ResourceDescriptionsData(emptyList)
				val fileMappings = generatedMappings.get(containerHandle)?.copy ?: new Source2GeneratedMapping
				state = new IndexState(indexChunk, fileMappings)
			}

			afterValidate = validator
			afterGenerateFile = [source, target| response.generatedFiles.add(new File(target.toFileString))]
			
			preparResourceSet(containerHandle, state.resourceDescriptions, gradleRequest)
		]
		
		val result = doBuild(request, gradleRequest)
		
		if (!validator.isErrorFree) {
			throw new GradleException("Xtext validation failed, see build log for details.")
		}
		
		val resultingIndex = result.indexState
		index.setContainer(containerHandle, resultingIndex.resourceDescriptions)
		generatedMappings.put(containerHandle, resultingIndex.fileMappings)
		return response
	}
	
	private def indexChangedClasspathEntries(GradleBuildRequest gradleRequest) {
		val registry = IResourceServiceProvider.Registry.INSTANCE
		gradleRequest.dirtyClasspathEntries.filter[exists].forEach[dirtyClasspathEntry|
			val hash = hash(dirtyClasspathEntry)
			if (dependencyHashes.get(dirtyClasspathEntry) != hash) {
				val containerHandle = dirtyClasspathEntry.path
				val request = new BuildRequest => [
					indexOnly = true
					/*
					 * TODO incremental jar indexing
					 * Only mark files as dirty that have changed in the jar,
					 * detect the deleted ones and reuse the existing index chunk for unchanged ones.
					 */
					dirtyFiles += new PathTraverser().findAllResourceUris(dirtyClasspathEntry.path) [uri|
						registry.getResourceServiceProvider(uri) !== null
					]
					
					afterValidate = [false] //workaround for indexOnly not working in Xtext 2.9.0
					
					val indexChunk = new ResourceDescriptionsData(emptyList)
					val fileMappings = new Source2GeneratedMapping
					state = new IndexState(indexChunk, fileMappings)
					preparResourceSet(containerHandle, indexChunk, gradleRequest)
				]
				
				val result = doBuild(request, gradleRequest)
				val resultingIndex = result.indexState
				index.setContainer(containerHandle, resultingIndex.resourceDescriptions)
				dependencyHashes.put(dirtyClasspathEntry, hash)
			}
		]
	}
	
	private def HashCode hash(File file) {
		val hasher = Hashing.md5.newHasher
		hash(file, hasher)
		hasher.hash
	}
	
	private def void hash(File file, Hasher hasher) {
		if (file.isDirectory) {
			file.listFiles.forEach[hash(hasher)]
		} else {
			Files.asByteSource(file).copyTo(Funnels.asOutputStream(hasher))
		}
	}
	
	private def preparResourceSet(BuildRequest it, String containerHandle, ResourceDescriptionsData indexChunk, GradleBuildRequest gradleRequest) {
		resourceSet = sharedInjector.getInstance(XtextResourceSet) => [
			classpathURIContext = gradleRequest.jvmTypesLoader
			attachProjectConfig(gradleRequest)
			attachGeneratorConfig(gradleRequest)
			attachOutputConfig(gradleRequest)
			attachPreferences(gradleRequest)
			attachProjectDescription(containerHandle, gradleRequest.allClasspathEntries.map[path].toList, it)
			val contextualIndex = index.createShallowCopyWith(it)
			contextualIndex.setContainer(containerHandle, indexChunk)
		]
	}
	
	private def doBuild(BuildRequest request, GradleBuildRequest gradleRequest) {
		try {
			val registry = IResourceServiceProvider.Registry.INSTANCE
			if (needsCleanBuild(gradleRequest)) {
				doClean(gradleRequest)
			}
			incrementalbuilder.build(request, [uri| registry.getResourceServiceProvider(uri)])
		} finally {
			cleanup(gradleRequest, request)
		}
	}
	
	private def doClean(GradleBuildRequest request) {
		request.generatorConfigsByLanguage.values
			.map[outputConfigs].flatten
			.filter[cleanAutomatically]
			.map[target]
			.forEach[
				deleteRecursive
			]
	}
	
	private def void deleteRecursive(File file) {
		if (file.isDirectory) {
			file.listFiles.forEach[deleteRecursive]
		}
		file.delete
	}
	
	private def boolean needsCleanBuild(GradleBuildRequest request) {
		!request.incremental || !request.dirtyClasspathEntries.isEmpty || index.getContainer(request.containerHandle) === null
	}
	
	private def getJvmTypesLoader(GradleBuildRequest gradleRequest) {
		val parent = if (gradleRequest.bootstrapClasspath === null || gradleRequest.bootstrapClasspath.empty) {
			ClassLoader.systemClassLoader
		} else {
			new AlternateJdkLoader(gradleRequest.bootstrapClasspath)
		}
		new URLClassLoader(gradleRequest.allClasspathEntries.map[toURI.toURL], parent)
	}
	
	private def cleanup(GradleBuildRequest gradleRequest, BuildRequest request) {
		val resourceSet = request.resourceSet
		val jvmTypesLoader = resourceSet.classpathURIContext
		if (jvmTypesLoader instanceof Closeable) {
			try {
				jvmTypesLoader.close
			} catch (Exception e) {
				gradleRequest.logger.debug("Couldn't close jvm types classloader", e)
			}
		}
		resourceSet.resources.clear
		resourceSet.eAdapters.clear
	}
	
	private def attachProjectConfig(XtextResourceSet resourceSet, GradleBuildRequest gradleRequest) {
		ProjectConfigAdapter.install(resourceSet, new GradleProjectConfig(gradleRequest))
	}
	
	private def attachProjectDescription(String containerHandle, List<String> dependencies, XtextResourceSet resourceSet) {
		new ProjectDescription => [
			name = containerHandle
			it.dependencies = dependencies
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
						outputDirectory = gradleOutputConfig.target.absolutePath
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
	
	override void installDebugInfo(GradleInstallDebugInfoRequest gradleRequest) {
		val request = new InstallDebugInfoRequest => [
			classesDir = gradleRequest.classesDir
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
