package org.xtext.gradle

import org.apache.maven.artifact.versioning.ComparableVersion
import org.gradle.api.Project
import org.gradle.api.internal.project.ProjectInternal
import org.gradle.internal.reflect.Instantiator

class GradleExtensions {

	static def supportsJvmEcoSystemplugin(Project project) {
		new ComparableVersion(project.gradle.gradleVersion) >= new ComparableVersion("6.7")
	}

	static def <T> T instantiate(Project project, Class<T> type, Object... args) {
		(project as ProjectInternal).services.get(typeof(Instantiator)).newInstance(type, args)
	}
}
