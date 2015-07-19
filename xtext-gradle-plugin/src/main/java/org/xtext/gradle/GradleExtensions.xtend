package org.xtext.gradle

import java.util.concurrent.Callable
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.gradle.api.Project
import org.gradle.api.artifacts.ExternalModuleDependency
import org.gradle.api.artifacts.dsl.DependencyHandler

class GradleExtensions {

	static def externalModule(DependencyHandler dependencyHandler, String coordinates, Procedure1<ExternalModuleDependency> config) {
		val dependency = dependencyHandler.create(coordinates)
		config.apply(dependency as ExternalModuleDependency)
		dependency
	}
	
	
	static def lazyFileCollection(Project project, Callable<?> fileSupplier) {
		project.files(fileSupplier)
	}
}
