package org.xtext.gradle

import groovy.lang.Closure
import java.util.Map
import org.eclipse.xtext.xbase.lib.Functions.Function0
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.gradle.api.Project
import org.gradle.api.Task
import org.gradle.api.artifacts.ExternalModuleDependency
import org.gradle.api.artifacts.dsl.DependencyHandler
import org.gradle.api.file.CopySpec
import org.gradle.api.internal.IConventionAware
import org.gradle.process.JavaExecSpec

class GradleExtensions {
	static def conventionMapping(Task task, Map<String, ? extends Function0<?>> mappings) {
		mappings.forEach[key, value|task.conventionMapping.map(key, value)]
	}

	static def conventionMapping(Task task) {
		(task as IConventionAware).conventionMapping
	}

	static def externalModule(DependencyHandler dependencyHandler, String coordinates,
		Procedure1<ExternalModuleDependency> config) {
		val dependency = dependencyHandler.create(coordinates)
		config.apply(dependency as ExternalModuleDependency)
		dependency
	}

	static def copy(Project project, Procedure1<CopySpec> copySpec) {
		project.copy(copySpec.toGroovyClosure)
	}

	static def javaexec(Project project, Procedure1<JavaExecSpec> execSpec) {
		project.javaexec(execSpec.toGroovyClosure)
	}

	static def <T> toGroovyClosure(Function0<T> function) {
		new Closure<T>(null) {
			override call() {
				function.apply
			}
		}
	}

	static def <T> toGroovyClosure(Procedure1<T> function) {
		new Closure<Void>(null) {
			override getMaximumNumberOfParameters() {
				1
			}

			override call(Object arg) {
				function.apply(arg as T)
				null
			}
		}
	}
}
