package org.xtext.gradle

import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.gradle.api.artifacts.ExternalModuleDependency
import org.gradle.api.artifacts.dsl.DependencyHandler

class GradleExtensions {

	static def externalModule(DependencyHandler dependencyHandler, String coordinates, Procedure1<ExternalModuleDependency> config) {
		val dependency = dependencyHandler.create(coordinates)
		config.apply(dependency as ExternalModuleDependency)
		dependency
	}
	
	static def externalModule(DependencyHandler dependencyHandler, String coordinates) {
		dependencyHandler.externalModule(coordinates)[]
	}

}
