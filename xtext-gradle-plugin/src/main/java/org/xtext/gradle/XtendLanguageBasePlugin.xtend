package org.xtext.gradle

import java.util.concurrent.Callable
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.file.FileCollection
import org.gradle.api.plugins.JavaBasePlugin
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate

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
		project.tasks.withType(XtextGenerate).all[
			project.afterEvaluate[p|
				//TODO gradle bug: composite file collection resolves when trying to find the build dependencies
				xtextClasspath = xtextClasspath.plus(getXtendBuilderDependencies(project, classpath))
			]
		]
	}
	
	def FileCollection getXtendBuilderDependencies(Project project, FileCollection classpath) {
		val extension xtext = project.extensions.getByType(XtextExtension)
		project.files([|
			val version = classpath.xtextVersion
			if (version != null) {
				val dependencies = #[
					project.dependencies.externalModule("org.eclipse.xtend:org.eclipse.xtend.core:" + version)[
						exclude(#{'group' -> 'asm'})
						force = true
					]
				]
				return project.configurations.detachedConfiguration(dependencies)
			}
			throw new GradleException('''Could not infer Xtend classpath, because xtext.version was not set and no Xtend libraries were found on the «classpath» classpath''')
		] as Callable<FileCollection>)
		.builtBy(classpath.buildDependencies)
	}
	
}