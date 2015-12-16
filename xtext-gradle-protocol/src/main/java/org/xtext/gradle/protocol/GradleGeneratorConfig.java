package org.xtext.gradle.protocol;

import java.util.Set;

import org.gradle.api.JavaVersion;

import com.google.common.collect.Sets;

public class GradleGeneratorConfig {
	private boolean generateSyntheticSuppressWarnings = true;
	private boolean generateGeneratedAnnotation = false;
	private boolean includeDateInGeneratedAnnotation = false;
	private String generatedAnnotationComment;
	private JavaVersion javaSourceLevel = JavaVersion.VERSION_1_6;
	private Set<GradleOutputConfig> outputConfigs = Sets.newHashSet();

	public boolean isGenerateSyntheticSuppressWarnings() {
		return generateSyntheticSuppressWarnings;
	}

	public void setGenerateSyntheticSuppressWarnings(boolean generateSyntheticSuppressWarnings) {
		this.generateSyntheticSuppressWarnings = generateSyntheticSuppressWarnings;
	}

	public boolean isGenerateGeneratedAnnotation() {
		return generateGeneratedAnnotation;
	}

	public void setGenerateGeneratedAnnotation(boolean generateGeneratedAnnotation) {
		this.generateGeneratedAnnotation = generateGeneratedAnnotation;
	}

	public boolean isIncludeDateInGeneratedAnnotation() {
		return includeDateInGeneratedAnnotation;
	}

	public void setIncludeDateInGeneratedAnnotation(boolean includeDateInGeneratedAnnotation) {
		this.includeDateInGeneratedAnnotation = includeDateInGeneratedAnnotation;
	}

	public String getGeneratedAnnotationComment() {
		return generatedAnnotationComment;
	}

	public void setGeneratedAnnotationComment(String generatedAnnotationComment) {
		this.generatedAnnotationComment = generatedAnnotationComment;
	}

	public JavaVersion getJavaSourceLevel() {
		return javaSourceLevel;
	}

	public void setJavaSourceLevel(JavaVersion javaSourceLevel) {
		this.javaSourceLevel = javaSourceLevel;
	}

	public Set<GradleOutputConfig> getOutputConfigs() {
		return outputConfigs;
	}

	public void setOutputConfigs(Set<GradleOutputConfig> outputConfigs) {
		this.outputConfigs = outputConfigs;
	}
}
