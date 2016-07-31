package org.xtext.gradle.protocol;

public interface IncrementalXtextBuilder {
	GradleBuildResponse build(GradleBuildRequest request);
	void installDebugInfo(GradleInstallDebugInfoRequest request);
	boolean needsCleanBuild(String containerHandle);
}
