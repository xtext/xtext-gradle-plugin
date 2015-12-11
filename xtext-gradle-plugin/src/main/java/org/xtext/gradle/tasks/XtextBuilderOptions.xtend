package org.xtext.gradle.tasks

import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Optional

@Accessors
class XtextBuilderOptions {
	@Input boolean incremental = true
	@Input @Optional String encoding
}