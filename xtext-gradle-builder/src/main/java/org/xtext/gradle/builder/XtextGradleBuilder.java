package org.xtext.gradle.builder;

import static org.eclipse.xtext.util.UriUtil.createFolderURI;

import java.io.File;
import java.util.Collections;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.ISetup;
import org.eclipse.xtext.build.BuildRequest;
import org.eclipse.xtext.build.IncrementalBuilder;
import org.eclipse.xtext.build.IncrementalBuilder.Result;
import org.eclipse.xtext.build.IndexState;
import org.eclipse.xtext.build.Source2GeneratedMapping;
import org.eclipse.xtext.generator.OutputConfiguration;
import org.eclipse.xtext.generator.OutputConfigurationAdapter;
import org.eclipse.xtext.parser.IEncodingProvider;
import org.eclipse.xtext.resource.IResourceDescription;
import org.eclipse.xtext.resource.IResourceServiceProvider;
import org.eclipse.xtext.resource.IResourceServiceProvider.Registry;
import org.eclipse.xtext.resource.XtextResourceSet;
import org.eclipse.xtext.resource.impl.ChunkedResourceDescriptions;
import org.eclipse.xtext.resource.impl.ProjectDescription;
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData;
import org.eclipse.xtext.workspace.WorkspaceConfigAdapter;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.gradle.api.GradleException;
import org.gradle.api.Project;
import org.xtext.gradle.protocol.GradleBuildRequest;
import org.xtext.gradle.protocol.GradleOutputConfig;

import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.inject.Guice;
import com.google.inject.Injector;
public class XtextGradleBuilder {
	private final ChunkedResourceDescriptions index = new ChunkedResourceDescriptions();
	private final ConcurrentMap<String, Source2GeneratedMapping> generatedMappings = new ConcurrentHashMap<String, Source2GeneratedMapping>();
	private final Injector sharedInjector = Guice.createInjector();
	private final IncrementalBuilder incrementalbuilder = sharedInjector.getInstance(IncrementalBuilder.class);
	private Set<String> languageSetups;
	private String encoding;
	
	public XtextGradleBuilder(Set<String> setupNames, String encoding) throws Exception {
		for (String setupName : setupNames) {
			Class<?> setupClass = getClass().getClassLoader().loadClass(setupName);
			ISetup setup= (ISetup) setupClass.newInstance();
			Injector injector = setup.createInjectorAndDoEMFRegistration();
			injector.getInstance(IEncodingProvider.Runtime.class).setDefaultEncoding(encoding);
		}
		this.languageSetups = setupNames;
		this.encoding = encoding;
	}
	
	public Set<String> getLanguageSetups() {
		return languageSetups;
	}
	
	public String getEncoding() {
		return encoding;
	}

	public void build(GradleBuildRequest gradleRequest) {
		Project project = gradleRequest.getProject();
		
		BuildRequest request = new BuildRequest();
		
		request.setBaseDir(createFolderURI(project.getProjectDir()));
		
		for (File dirtyFile : gradleRequest.getDirtyFiles()) {
			request.getDirtyFiles().add(URI.createFileURI(dirtyFile.getAbsolutePath()));
		}
		for (File deletedFile : gradleRequest.getDeletedFiles()) {
			request.getDeletedFiles().add(URI.createFileURI(deletedFile.getAbsolutePath()));
		}
		
		String containerHandle = project.getPath();
		ResourceDescriptionsData indexChunk = index.getContainer(containerHandle);
		if (indexChunk == null) {
			indexChunk = new ResourceDescriptionsData(Collections.<IResourceDescription>emptyList());
		} else {
			indexChunk = indexChunk.copy();
		}
		Source2GeneratedMapping fileMappings = generatedMappings.get(containerHandle);
		if (fileMappings == null) {
			fileMappings = new Source2GeneratedMapping();
		} else {
			fileMappings = fileMappings.copy();
		}
		
		request.setState(new IndexState(indexChunk, fileMappings));
		
		XtextResourceSet resourceSet = sharedInjector.getInstance(XtextResourceSet.class);
		resourceSet.eAdapters().add(new WorkspaceConfigAdapter(new GradleWorkspaceConfig(gradleRequest)));
		Map<String, Set<OutputConfiguration>> outputConfigurationsPerLanguage = Maps.newHashMap();
		for (Entry<String, Set<GradleOutputConfig>> gradleOutputConfigs : gradleRequest.getOutputConfigsPerLanguage().entrySet()) {
			Set<OutputConfiguration> outputConfigs = Sets.newHashSet();
			for (GradleOutputConfig gradleOutputConfig : gradleOutputConfigs.getValue()) {
				OutputConfiguration outputConfig = new OutputConfiguration(gradleOutputConfig.getOutletName());
				outputConfig.setOutputDirectory(URI.createFileURI(gradleOutputConfig.getTarget().getAbsolutePath()).toString());
				outputConfigs.add(outputConfig);
			}
			outputConfigurationsPerLanguage.put(gradleOutputConfigs.getKey(), outputConfigs);
		}
		resourceSet.eAdapters().add(new OutputConfigurationAdapter(outputConfigurationsPerLanguage));
		resourceSet.setClasspathURIContext(new FileClassLoader(gradleRequest.getClassPath(), ClassLoader.getSystemClassLoader()));
		ProjectDescription projectDescription = new ProjectDescription();
		projectDescription.setName(containerHandle);
		//TODO dependencies
		projectDescription.attachToEmfObject(resourceSet);
		ChunkedResourceDescriptions contextualIndex = index.createShallowCopyWith(resourceSet);
		contextualIndex.setContainer(containerHandle, indexChunk);
		
		request.setResourceSet(resourceSet);
		
		GradleValidatonCallback validator = new GradleValidatonCallback(project.getLogger());
		request.setAfterValidate(validator);
		
		final Registry registry = IResourceServiceProvider.Registry.INSTANCE;
		Result result = incrementalbuilder.build(request, new Function1<URI, IResourceServiceProvider>() {
			@Override
			public IResourceServiceProvider apply(URI uri) {
				return registry.getResourceServiceProvider(uri);
			}
		});
		IndexState resultingIndex = result.getIndexState();
		if (!validator.isErrorFree()) {
			throw new GradleException("Xtext validation failed, see build log for details.");
		}
		index.setContainer(containerHandle, resultingIndex.getResourceDescriptions());
		generatedMappings.put(containerHandle, resultingIndex.getFileMappings());
	}
}
