package org.xtext.gradle

import org.gradle.api.Project
import org.gradle.util.VersionNumber

class GradleExtensions {

	static def supportsJvmEcoSystemplugin(Project project) {
		VersionNumber.parse(project.gradle.gradleVersion) >= VersionNumber.parse("6.7")
	}
}
