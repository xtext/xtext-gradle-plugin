package org.xtext.gradle.tasks

import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input

abstract class XtextBuilderOptions {
	@Input 
	abstract def Property<Boolean> getIncremental()
	
	@Input 
	abstract def Property<String> getEncoding()
}