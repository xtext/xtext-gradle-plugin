package org.xtext.gradle.android

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.xtext.gradle.XtendLanguageBasePlugin
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.XtextExtension

class XtendAndroidBuilderPlugin implements Plugin<Project> {

	override apply(Project project) {
		project.apply[plugin(XtextAndroidBuilderPlugin)]
		project.apply[plugin(XtendLanguageBasePlugin)]

		val xtext = project.extensions.getByType(XtextExtension)
		xtext.languages.getAt("xtend") => [
			debugger => [
				sourceInstaller = SourceInstaller.PRIMARY
				hideSyntheticVariables = false
			]
		]
	}
}