package org.xtext.gradle

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.XtextExtension
import org.gradle.api.plugins.JavaBasePlugin
import static extension org.xtext.gradle.GradleExtensions.*
class XtendLanguageBasePlugin implements Plugin<Project> {
	
	override apply(Project project) {
		project.apply[plugin(JavaBasePlugin)]
		project.apply[plugin(XtextBuilderPlugin)]
		project.apply[plugin(XtextJavaLanguagePlugin)]
		val xtext = project.extensions.getByType(XtextExtension)
		xtext.languages.create("xtend")[
			fileExtension = "xtend"
			setup = "org.eclipse.xtend.core.XtendStandaloneSetup"
			generator.outlet.producesJava = true
			debugger => [
				sourceInstaller = SourceInstaller.SMAP
			]
		]
		project.afterEvaluate[
			project.dependencies => [
				add("xtextTooling", externalModule("org.eclipse.xtend:org.eclipse.xtend.core:" + xtext.version)[
					exclude(#{'group' -> 'asm'})
				])
			]
		]
	}
	
}