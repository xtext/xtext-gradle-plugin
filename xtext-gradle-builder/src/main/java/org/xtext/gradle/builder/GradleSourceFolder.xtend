package org.xtext.gradle.builder

import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.workspace.ISourceFolder
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.annotations.Accessors

@FinalFieldsConstructor
class GradleSourceFolder implements ISourceFolder {
	val GradleProjectConfig parent
	@Accessors
	val URI path

	override getName() {
		path.deresolve(parent.path).trimSegments(1).path
	}
}
