package org.xtext.gradle.protocol;

import java.io.File;
import java.util.Collection;
import java.util.Map;

import org.gradle.api.file.FileCollection;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

public class GradleInstallDebugInfoRequest {

	private File classesDir;
	private Collection<File> generatedJavaFiles = Lists.newArrayList();
	private Map<String, GradleSourceInstallerConfig> sourceInstallerByFileExtension = Maps.newHashMap();

	public File getClassesDir() {
		return classesDir;
	}

	public void setClassesDir(File classesDir) {
		this.classesDir = classesDir;
	}
	
	public Map<String, GradleSourceInstallerConfig> getSourceInstallerByFileExtension() {
		return sourceInstallerByFileExtension;
	}
	
	public void setSourceInstallerByFileExtension(Map<String, GradleSourceInstallerConfig> sourceInstallerByFileExtension) {
		this.sourceInstallerByFileExtension = sourceInstallerByFileExtension;
	}
	public Collection<File> getGeneratedJavaFiles() {
		return generatedJavaFiles;
	}

	public void setGeneratedJavaFiles(Collection<File> generatedJavaFiles) {
		this.generatedJavaFiles = generatedJavaFiles;
	}
	public static class GradleSourceInstallerConfig {
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
