package org.xtext.gradle.builder

import com.google.common.collect.Sets
import org.eclipse.emf.common.util.URI
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.util.UriUtil
import org.eclipse.xtext.workspace.IProjectConfig
import org.eclipse.xtext.workspace.ISourceFolder
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


@FinalFieldsConstructor
class GradleProjectConfig implements IProjectConfig {
	val GradleBuildRequest request

	override getName() {
		request.projectName
	}

	override getPath() {
		UriUtil.createFolderURI(request.projectDir)
	}

	override getSourceFolders() {
		request.sourceFolders.map [
			val uri = UriUtil::createFolderURI(it)
			new GradleSourceFolder(this, uri)

		].toSet
	}

	override findSourceFolderContaining(URI member) {
		sourceFolders.findFirst[UriUtil::isPrefixOf(path, member)]
	}
}

@FinalFieldsConstructor
class GradleSourceFolder implements ISourceFolder {
	val GradleProjectConfig parent
	@Accessors
	val URI path

	override getName() {
		path.deresolve(parent.path).trimSegments(1).path
	}
}
