package org.xtext.gradle

import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.file.FileCollection
import org.gradle.api.internal.plugins.DslObject
import org.gradle.api.plugins.JavaBasePlugin
import org.gradle.api.plugins.JavaPluginConvention
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.XtextClasspathInferrer
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextSourceDirectorySet
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
		val xtend = xtext.languages.create("xtend") [
			fileExtension = "xtend"
			setup = "org.eclipse.xtend.core.XtendStandaloneSetup"
			generator.outlet => [
				producesJava = true
				cleanAutomatically = true
			]
			debugger => [
				sourceInstaller = SourceInstaller.SMAP
			]
		]
		automaticallyInferXtendCompilerClasspath
		project.extensions.add("xtend", xtend)
		val java = project.convention.getPlugin(JavaPluginConvention)
		java.sourceSets.all [ sourceSet |
			val xtendSourceSet = new XtendSourceSet(
				xtext.sourceSets.getAt(sourceSet.name),
				xtend.generator.outlet
			)
			//TODO get rid of this internal API usage
			new DslObject(sourceSet).convention.plugins.put("xtend", xtendSourceSet)
		]
	}

	private def void automaticallyInferXtendCompilerClasspath() {
		xtext.classpathInferrers += new XtextClasspathInferrer() {
			override inferXtextClasspath(XtextSourceDirectorySet sourceSet, FileCollection xtextClasspath, FileCollection classpath) {
				val version = xtext.getXtextVersion(classpath) ?: xtext.getXtextVersion(xtextClasspath)
				if (version === null) {
					throw new GradleException('''Could not infer Xtext classpath, because xtext.version was not set and no xtext libraries were found on the «classpath» classpath''')
				}
				val xtendTooling = project.configurations.create(sourceSet.qualifyConfigurationName("xtendTooling"))
				xtendTooling.dependencies += project.dependencies.create("org.eclipse.xtend:org.eclipse.xtend.core:" + version)
				xtext.makeXtextCompatible(xtendTooling)
				xtext.forceXtextVersion(xtendTooling, version)
				xtendTooling.plus(xtextClasspath)
			}
		}
	}
}
