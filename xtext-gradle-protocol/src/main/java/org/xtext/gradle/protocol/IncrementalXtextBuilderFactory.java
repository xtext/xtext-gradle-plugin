package org.xtext.gradle.protocol;

import java.util.Set;

public interface IncrementalXtextBuilderFactory {
	public IncrementalXtextBuilder get(Set<String> setupNames, String encoding);
}
