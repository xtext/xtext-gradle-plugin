package org.xtext.gradle

import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.gradle.api.artifacts.ExternalModuleDependency
import org.gradle.api.artifacts.dsl.DependencyHandler
import org.gradle.api.Project
import org.gradle.util.VersionNumber

class GradleExtensions {

	static def externalModule(DependencyHandler dependencyHandler, String coordinates, Procedure1<ExternalModuleDependency> config) {
		val dependency = dependencyHandler.create(coordinates)
		config.apply(dependency as ExternalModuleDependency)
		dependency
	}

	static def externalModule(DependencyHandler dependencyHandler, String coordinates) {
		dependencyHandler.externalModule(coordinates)[]
	}

	static def enforcedPlatform(DependencyHandler dependencyHandler, String coordinates) {
		val m = DependencyHandler.getDeclaredMethod("enforcedPlatform", Object)
		m.invoke(dependencyHandler, coordinates) as ExternalModuleDependency
	}

	static def supportsJvmEcoSystemplugin(Project project) {
		VersionNumber.parse(project.gradle.gradleVersion) >= VersionNumber.parse("6.7")
	}
}
