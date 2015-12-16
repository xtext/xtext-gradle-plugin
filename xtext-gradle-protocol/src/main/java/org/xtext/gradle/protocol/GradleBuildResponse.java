package org.xtext.gradle.protocol;

import java.io.File;
import java.util.Collection;

import com.google.common.collect.Lists;

public class GradleBuildResponse {
	private Collection<File> generatedFiles = Lists.newArrayList();

	public Collection<File> getGeneratedFiles() {
		return generatedFiles;
	}

	public void setGeneratedFiles(Collection<File> generatedFiles) {
		this.generatedFiles = generatedFiles;
	}
}
