package org.xtext.gradle.protocol;

import java.io.File;
import java.util.Collection;
import java.util.Map;
import java.util.Set;

import org.gradle.api.Project;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

public class GradleBuildRequest {
	/*
	 * TODO pass individual properties instead, to make sure the builder doesn't randomly access the project model,
	 * possibly bypassing up-to-date checks
	 */
	private Project project;  
	private Collection<File> dirtyFiles = Lists.newArrayList();
	private Collection<File> deletedFiles = Lists.newArrayList();
	private ClassLoader classPath;
	private Collection<File> sourceFolders = Lists.newArrayList();
	private Map<String, Set<GradleOutputConfig>> outputConfigsPerLanguage = Maps.newHashMap();
	
	public Project getProject() {
		return project;
	}
	
	public void setProject(Project project) {
		this.project = project;
	}
	
	//TODO maybe pass URLs instead?
	public ClassLoader getClassPath() {
		return classPath;
	}
	
	public void setClassPath(ClassLoader classPath) {
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
}
