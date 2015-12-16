package org.xtext.gradle.protocol;

import java.util.Set;

public interface IncrementalXtextBuilder {
	GradleBuildResponse build(GradleBuildRequest request);
	void installDebugInfo(GradleInstallDebugInfoRequest request);
	boolean isCompatible(String owner, Set<String> languageSetups, String encoding);
	boolean needsCleanBuild(String containerHandle);
}
