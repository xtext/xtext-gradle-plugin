package org.xtext.gradle

import org.gradle.api.Project
import org.gradle.api.internal.project.ProjectInternal
import org.gradle.internal.reflect.Instantiator
import org.xtext.gradle.tasks.internal.Version

class GradleExtensions {

	static def supportsJvmEcoSystemplugin(Project project) {
		Version.parse(project.gradle.gradleVersion) >= Version.parse("6.7")
	}

	static def <T> T instantiate(Project project, Class<T> type, Object... args) {
		(project as ProjectInternal).services.get(typeof(Instantiator)).newInstance(type, args)
	}
}
