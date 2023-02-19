package org.xtext.gradle.protocol;

import java.io.File;
import java.util.Collection;
import java.util.Map;

import org.gradle.api.file.FileCollection;
import org.gradle.api.logging.Logger;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

public class GradleBuildRequest {
	private Logger logger;
	private String containerHandle;
	private File projectDir;
	private String projectName;
	private boolean incremental;
	private Collection<File> allFiles = Lists.newArrayList();
	private Collection<File> dirtyFiles = Lists.newArrayList();
	private Collection<File> deletedFiles = Lists.newArrayList();
	private Collection<File> allClasspathEntries = Lists.newArrayList();
	private Collection<File> dirtyClasspathEntries = Lists.newArrayList();
	private Collection<File> sourceFolders = Lists.newArrayList();
	private Map<String, GradleGeneratorConfig> generatorConfigsByLanguage = Maps.newHashMap();
	private Map<String, Map<String, String>> preferencesByLanguage = Maps.newHashMap();
	private File classesDir;
	
	public boolean isIncremental() {
		return incremental;
	}
	
	public void setIncremental(boolean incremental) {
		this.incremental = incremental;
	}
	
	public Collection<File> getAllFiles() {
		return allFiles;
	}
	
	public void setAllFiles(Collection<File> allFiles) {
		this.allFiles = allFiles;
	}
	
	public Collection<File> getAllClasspathEntries() {
		return allClasspathEntries;
	}
	
	public void setAllClasspathEntries(Collection<File> allClasspathEntries) {
		this.allClasspathEntries = allClasspathEntries;
	}
	
	public Collection<File> getDirtyClasspathEntries() {
		return dirtyClasspathEntries;
	}
	
	public void setDirtyClasspathEntries(Collection<File> dirtyClasspathEntries) {
		this.dirtyClasspathEntries = dirtyClasspathEntries;
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
	
	public Map<String, GradleGeneratorConfig> getGeneratorConfigsByLanguage() {
		return generatorConfigsByLanguage;
	}
	
	public void setGeneratorConfigsByLanguage(Map<String, GradleGeneratorConfig> generatorConfigsByLanguage) {
		this.generatorConfigsByLanguage = generatorConfigsByLanguage;
	}

	public Map<String, Map<String, String>> getPreferencesByLanguage() {
		return preferencesByLanguage;
	}

	public void setPreferencesByLanguage(Map<String, Map<String, String>> preferencesByLanguage) {
		this.preferencesByLanguage = preferencesByLanguage;
	}
}
