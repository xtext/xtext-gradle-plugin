package org.xtext.gradle.builder

import com.google.common.collect.Sets
import org.eclipse.emf.common.util.URI
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.util.UriUtil
import org.eclipse.xtext.workspace.IWorkspaceConfig
import org.xtext.gradle.protocol.GradleBuildRequest

@FinalFieldsConstructor
class GradleWorkspaceConfig implements IWorkspaceConfig {
	val GradleBuildRequest request

	override findProjectContaining(URI member) {
		projects.findFirst [ p |
			UriUtil.isPrefixOf(p.path, member)
		]
	}

	override findProjectByName(String name) {
		projects.findFirst [ p |
			p.name == name
		]
	}

	override getProjects() {
		Sets.newHashSet(new GradleProjectConfig(request))
	}
}
