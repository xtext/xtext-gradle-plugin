package org.xtext.gradle

import org.gradle.api.Project
import org.gradle.api.Plugin
import org.xtext.gradle.tasks.XtextExtension

class XtextJavaLanguagePlugin implements Plugin<Project> {

	override apply(Project project) {
		project.plugins.<XtextBuilderPlugin>apply(XtextBuilderPlugin)
		val xtext = project.extensions.getByType(XtextExtension)
		xtext.languages.maybeCreate("java") => [
			setup.set("org.eclipse.xtext.java.JavaSourceLanguageSetup")
			qualifiedName.set("org.eclipse.xtext.java.Java")
			generator.outlets.clear
		]
	}
}
