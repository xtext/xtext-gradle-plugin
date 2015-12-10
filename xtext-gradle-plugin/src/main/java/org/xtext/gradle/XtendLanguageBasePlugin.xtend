package org.xtext.gradle

import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.JavaBasePlugin
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate

import static extension org.xtext.gradle.GradleExtensions.*

class XtendLanguageBasePlugin implements Plugin<Project> {
	
	Project project
	XtextExtension xtext
	
	override apply(Project project) {
		this.project = project
		project.apply[plugin(JavaBasePlugin)]
		project.apply[plugin(XtextBuilderPlugin)]
		project.apply[plugin(XtextJavaLanguagePlugin)]
		xtext = project.extensions.getByType(XtextExtension)
		val xtend = xtext.languages.create("xtend")[
			fileExtension = "xtend"
			setup = "org.eclipse.xtend.core.XtendStandaloneSetup"
			generator.outlet.producesJava = true
			debugger => [
				sourceInstaller = SourceInstaller.SMAP
			]
		]
		project.extensions.add("xtend", xtend)
		project.tasks.withType(XtextGenerate).all[
			enhanceBuilderDependencies
		]
	}
	
	def void enhanceBuilderDependencies(XtextGenerate generatorTask) {
		generatorTask.beforeExecute[
			val builderClasspathBefore = generatorTask.xtextClasspath
			val classpath = generatorTask.classpath
			val version = xtext.getXtextVersion(classpath) ?: xtext.getXtextVersion(builderClasspathBefore)
			if (version === null) {
				throw new GradleException('''Could not infer Xtend compiler classpath, because xtext.version was not set and no Xtend libraries were found on the «classpath» classpath''')
			}
			val xtendCore = project.dependencies.externalModule("org.eclipse.xtend:org.eclipse.xtend.core:" + version)
			val xtendTooling = project.configurations.detachedConfiguration(xtendCore)
			xtext.makeXtextCompatible(xtendTooling)
			xtext.forceXtextVersion(xtendTooling, version)
			generatorTask.xtextClasspath = xtendTooling.plus(builderClasspathBefore)
		]
	}
}