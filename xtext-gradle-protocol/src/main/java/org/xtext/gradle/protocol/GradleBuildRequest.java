package org.xtext.gradle.protocol;

import java.io.File;
import java.util.Collection;
import java.util.Map;
import java.util.Set;

import org.gradle.api.logging.Logger;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

public class GradleBuildRequest {
	private Logger logger;
	private String containerHandle;
	private File projectDir;
	private String projectName;
	private Collection<File> dirtyFiles = Lists.newArrayList();
	private Collection<File> deletedFiles = Lists.newArrayList();
	private Collection<File> classPath;
	private Collection<File> sourceFolders = Lists.newArrayList();
	private Map<String, Set<GradleOutputConfig>> outputConfigsPerLanguage = Maps.newHashMap();
	private File classesDir;
	
	public Collection<File> getClassPath() {
		return classPath;
	}
	
	public void setClassPath(Collection<File> classPath) {
		this.classPath = classPath;
	}

	public Collection<File> getDirtyFiles() {
		return dirtyFiles;
	}
	
	public void setDirtyFiles(Collection<File> dirtyFiles) {
		this.dirtyFiles = dirtyFiles;
	}
	
	public Collection<File> getDeletedFiles() {
		return deletedFiles;
	}
	
	public void setDeletedFiles(Collection<File> deletedFiles) {
		this.deletedFiles = deletedFiles;
	}

	public Collection<File> getSourceFolders() {
		return sourceFolders;
	}
	
	public void setSourceFolders(Collection<File> sourceFolders) {
		this.sourceFolders = sourceFolders;
	}
	
	public Map<String, Set<GradleOutputConfig>> getOutputConfigsPerLanguage() {
		return outputConfigsPerLanguage;
	}
	
	public void setOutputConfigsPerLanguage(Map<String, Set<GradleOutputConfig>> outputConfigsPerLanguage) {
		this.outputConfigsPerLanguage = outputConfigsPerLanguage;
	}
	
	public File getClassesDir() {
		return classesDir;
	}
	
	public void setClassesDir(File classesDir) {
		this.classesDir = classesDir;
	}

	public String getContainerHandle() {
		return containerHandle;
	}

	public void setContainerHandle(String containerHandle) {
		this.containerHandle = containerHandle;
	}

	public File getProjectDir() {
		return projectDir;
	}

	public void setProjectDir(File projectDir) {
		this.projectDir = projectDir;
	}

	public String getProjectName() {
		return projectName;
	}

	public void setProjectName(String projectName) {
		this.projectName = projectName;
	}

	public Logger getLogger() {
		return logger;
	}

	public void setLogger(Logger logger) {
		this.logger = logger;
	}
}
