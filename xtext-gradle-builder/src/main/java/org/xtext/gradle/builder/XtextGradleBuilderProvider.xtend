package org.xtext.gradle.builder

import org.xtext.gradle.protocol.IncrementalXtextBuilderProvider
import java.util.Set

class XtextGradleBuilderProvider implements IncrementalXtextBuilderProvider {
	
	override get(String owner, Set<String> setupNames, String encoding) {
		new XtextGradleBuilder(owner, setupNames, encoding)
	}
	
}