package org.xtext.gradle.builder;

import java.io.File;
import java.util.Collection;
import java.util.Map;

import org.eclipse.emf.ecore.resource.ResourceSet;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

//TODO move to Xtext
public class InstallDebugInfoRequest {

	private Collection<File> generatedJavaFiles = Lists.newArrayList();
	private File classesDir;
	private File outputDir;
	private Map<String, SourceInstallerConfig> sourceInstallerByFileExtension = Maps.newHashMap();
	private ResourceSet resourceSet;

	public File getClassesDir() {
		return classesDir;
	}

	public void setClassesDir(File classesDir) {
		this.classesDir = classesDir;
	}

	public Collection<File> getGeneratedJavaFiles() {
		return generatedJavaFiles;
	}

	public void setGeneratedJavaFiles(Collection<File> generatedJavaFiles) {
		this.generatedJavaFiles = generatedJavaFiles;
	}

	public File getOutputDir() {
		return outputDir;
	}

	public void setOutputDir(File outputDir) {
		this.outputDir = outputDir;
	}
	
	public void setSourceInstallerByFileExtension(Map<String, SourceInstallerConfig> sourceInstallerByFileExtension) {
		this.sourceInstallerByFileExtension = sourceInstallerByFileExtension;
	}
	
	public Map<String, SourceInstallerConfig> getSourceInstallerByFileExtension() {
		return sourceInstallerByFileExtension;
	}
	
	public ResourceSet getResourceSet() {
		return resourceSet;
	}
	
	public void setResourceSet(ResourceSet resourceSet) {
		this.resourceSet = resourceSet;
	}

	public static class SourceInstallerConfig {
		private boolean hideSyntheticVariables;
		private SourceInstaller sourceInstaller;

		public boolean isHideSyntheticVariables() {
			return hideSyntheticVariables;
		}

		public void setHideSyntheticVariables(boolean hideSyntheticVariables) {
			this.hideSyntheticVariables = hideSyntheticVariables;
		}

		public SourceInstaller getSourceInstaller() {
			return sourceInstaller;
		}

		public void setSourceInstaller(SourceInstaller sourceInstaller) {
			this.sourceInstaller = sourceInstaller;
		}
	}
	
	public static enum SourceInstaller {
		PRIMARY,
		SMAP,
		NONE
	}
}
