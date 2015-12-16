package org.xtext.gradle

import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.gradle.api.Task
import org.gradle.api.artifacts.ExternalModuleDependency
import org.gradle.api.artifacts.dsl.DependencyHandler
import org.gradle.api.execution.TaskExecutionAdapter

class GradleExtensions {

	static def externalModule(DependencyHandler dependencyHandler, String coordinates, Procedure1<ExternalModuleDependency> config) {
		val dependency = dependencyHandler.create(coordinates)
		config.apply(dependency as ExternalModuleDependency)
		dependency
	}
	
	static def externalModule(DependencyHandler dependencyHandler, String coordinates) {
		dependencyHandler.externalModule(coordinates)[]
	}

	static def beforeExecute(Task task, (Task) => void action) {
		task.project.gradle.taskGraph.addTaskExecutionListener(new TaskExecutionAdapter() {
			override beforeExecute(Task someTask) {
				if (someTask == task) {
					action.apply(someTask)
				}
			}
		})
	}

}
