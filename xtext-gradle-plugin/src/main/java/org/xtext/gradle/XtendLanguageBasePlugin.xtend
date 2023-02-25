package org.xtext.gradle

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.ExtensionAware
import org.gradle.api.plugins.JavaBasePlugin
import org.gradle.api.plugins.JavaPluginExtension
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.internal.XtendSourceDirectorySet

class XtendLanguageBasePlugin implements Plugin<Project> {

	override apply(Project project) {
		project.apply [
			plugin(JavaBasePlugin)
			plugin(XtextBuilderPlugin)
		]
		val xtext = project.extensions.getByType(XtextExtension)
		xtext.sourceSets.all [
			project.dependencies.add(qualifyConfigurationName('xtextTooling'),
				'org.eclipse.xtend:org.eclipse.xtend.core')
		]
		val xtend = xtext.languages.create("xtend") [
			setup.set("org.eclipse.xtend.core.XtendStandaloneSetup")
			generator.outlet => [
				producesJava.set(true)
			]
			debugger => [
				sourceInstaller.set(SourceInstaller.SMAP.name)
			]
		]
		project.extensions.add("xtend", xtend)
		val java = project.extensions.getByType(JavaPluginExtension)
		java.sourceSets.all [ sourceSet |
			val xtendSources = xtext.sourceSets.getAt(sourceSet.name)
			val xtendGen = xtend.generator.outlet;
			(sourceSet as ExtensionAware).extensions.create("xtend", XtendSourceDirectorySet, xtendSources, xtendGen)
		]
	}
}
