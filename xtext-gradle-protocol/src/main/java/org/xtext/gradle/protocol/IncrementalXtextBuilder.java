package org.xtext.gradle.protocol;

import java.util.Set;

public interface IncrementalXtextBuilder {
	GradleBuildResponse build(GradleBuildRequest request);
	void installDebugInfo(GradleInstallDebugInfoRequest request);
	String getOwner();
	Set<String> getLanguageSetups();
	String getEncoding();
}
