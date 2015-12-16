package org.xtext.gradle.protocol;

import java.util.Iterator;
import java.util.ServiceLoader;
import java.util.Set;

public class IncrementalXtextBuilderFactory {
	public IncrementalXtextBuilder create(String owner, Set<String> setupNames, String encoding, ClassLoader classLoader) {
		ServiceLoader<IncrementalXtextBuilderProvider> loader = ServiceLoader.load(IncrementalXtextBuilderProvider.class, classLoader);
		Iterator<IncrementalXtextBuilderProvider> providers = loader.iterator();
		if (providers.hasNext()) {
			return providers.next().get(owner, setupNames, encoding);
		}
		throw new IllegalStateException("No IncrementalXtextBuilderProvider found on the classpath");
	}
}
