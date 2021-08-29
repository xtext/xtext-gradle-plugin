package org.xtext.gradle

import org.gradle.api.Project
import org.xtext.gradle.tasks.internal.Version

class GradleExtensions {

	static def supportsJvmEcoSystemplugin(Project project) {
		Version.parse(project.gradle.gradleVersion) >= Version.parse("6.7")
	}
}
