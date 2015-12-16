package org.xtext.gradle.builder

import java.util.Map
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.resource.impl.ChunkedResourceDescriptions
import org.eclipse.xtext.resource.impl.ProjectDescription
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData

class GradleResourceDescriptions extends ChunkedResourceDescriptions {
	new() {
	}

	new(Map<String, ResourceDescriptionsData> initialData, ResourceSet resourceSet) {
		super(initialData)
		setResourceSet(resourceSet)
	}

	override getAllResourceDescriptions() {
		visibleResourceDescriptions.map[it.getAllResourceDescriptions()].flatten
	}

	override getResourceDescription(URI uri) {
		for (selectable : visibleResourceDescriptions) {
			val result = selectable.getResourceDescription(uri)
			if (result != null)
				return result
		}
		return null
	}

	override protected getSelectables() {
		visibleResourceDescriptions
	}

	private def getVisibleResourceDescriptions() {
		val project = ProjectDescription.findInEmfObject(resourceSet)
		chunk2resourceDescriptions.filter[key, value|project.dependencies.contains(key) || project.name == key].values
	}

	override ChunkedResourceDescriptions createShallowCopyWith(ResourceSet resourceSet) {
		return new GradleResourceDescriptions(chunk2resourceDescriptions, resourceSet)
	}
}