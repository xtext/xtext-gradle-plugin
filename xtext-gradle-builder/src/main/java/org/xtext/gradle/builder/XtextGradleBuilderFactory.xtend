package org.xtext.gradle.builder

import java.util.Set
import org.xtext.gradle.protocol.IncrementalXtextBuilderFactory

class XtextGradleBuilderFactory implements IncrementalXtextBuilderFactory {
	
	override get(Set<String> setupNames, String encoding) {
		new XtextGradleBuilder(setupNames, encoding)
	}
	
}