package org.xtext.gradle.protocol;

import java.io.File;
import java.util.Map;
import java.util.Set;

import org.gradle.api.logging.Logger;

import com.google.common.collect.Maps;
import com.google.common.collect.Sets;

public class GradleBuildRequest {
	private Logger logger;
	private String containerHandle;
	private File projectDir;
	private String projectName;
	private boolean incremental;
	private final Set<File> allFiles = Sets.newHashSet();
	private final Set<File> dirtyFiles = Sets.newHashSet();
	private final Set<File> deletedFiles = Sets.newHashSet();
	private final Set<File> allClasspathEntries = Sets.newHashSet();
	private final Set<File> dirtyClasspathEntries = Sets.newHashSet();
	private final Set<File> sourceFolders = Sets.newHashSet();
	private final Map<String, GradleGeneratorConfig> generatorConfigsByLanguage = Maps.newHashMap();
	private final Map<String, Map<String, String>> preferencesByLanguage = Maps.newHashMap();
	private File classesDir;

	public boolean isIncremental() {
		return incremental;
	}

	public void setIncremental(boolean incremental) {
		this.incremental = incremental;
	}

	public Set<File> getAllFiles() {
		return allFiles;
	}

	public Set<File> getAllClasspathEntries() {
		return allClasspathEntries;
	}

	public Set<File> getDirtyClasspathEntries() {
		return dirtyClasspathEntries;
	}

	public Set<File> getDirtyFiles() {
		return dirtyFiles;
	}

	public Set<File> getDeletedFiles() {
		return deletedFiles;
	}

	public Set<File> getSourceFolders() {
		return sourceFolders;
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

	public Map<String, Map<String, String>> getPreferencesByLanguage() {
		return preferencesByLanguage;
	}
}
