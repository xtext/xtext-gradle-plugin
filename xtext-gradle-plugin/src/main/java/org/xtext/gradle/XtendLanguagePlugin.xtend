package org.xtext.gradle

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.JavaPlugin

class XtendLanguagePlugin implements Plugin<Project> {

	override apply(Project project) {
		project.apply[plugin(JavaPlugin)]
		project.apply[plugin(XtendLanguageBasePlugin)]
	}

}
