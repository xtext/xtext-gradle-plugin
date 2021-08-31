package org.xtext.gradle

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.internal.plugins.DslObject
import org.gradle.api.plugins.JavaBasePlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.internal.XtendSourceSet

class XtendLanguageBasePlugin implements Plugin<Project> {

	Project project
	XtextExtension xtext

	override apply(Project project) {
		this.project = project
		project.apply[
			plugin(JavaBasePlugin)
			plugin(XtextBuilderPlugin)
		]
		xtext = project.extensions.getByType(XtextExtension)
		xtext.sourceSets.all [
			project.dependencies.add(qualifyConfigurationName('xtextTooling'), 'org.eclipse.xtend:org.eclipse.xtend.core')
		]
		val xtend = xtext.languages.create("xtend") [
			setup = "org.eclipse.xtend.core.XtendStandaloneSetup"
			generator.outlet => [
				producesJava = true
			]
			debugger => [
				sourceInstaller = SourceInstaller.SMAP
			]
		]
		project.extensions.add("xtend", xtend)
		val java = project.convention.getPlugin(JavaPluginConvention)
		java.sourceSets.all [ sourceSet |
			val xtendSourceSet = new XtendSourceSet(
				xtext.sourceSets.getAt(sourceSet.name),
				xtend.generator.outlet
			)
			new DslObject(sourceSet).convention.plugins.put("xtend", xtendSourceSet)
		]
	}
}
