package org.xtext.gradle.protocol;

import java.util.Set;

public interface IncrementalXtextBuilderProvider {
	public IncrementalXtextBuilder get(String owner, Set<String> setupNames, String encoding);
}
