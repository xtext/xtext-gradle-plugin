package org.xtext.gradle.android

import com.android.build.gradle.AppExtension
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.LibraryExtension
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.xtext.gradle.XtextBuilderPlugin
import org.xtext.gradle.tasks.XtextExtension

class XtextAndroidBuilderPlugin implements Plugin<Project> {

	override apply(Project project) {
		project.plugins.<XtextBuilderPlugin>apply(XtextBuilderPlugin)
		val xtext = project.extensions.getByType(XtextExtension)
		project.afterEvaluate [
			val android = project.extensions.getByName("android") as BaseExtension
			val variants = switch android {
				AppExtension: android.applicationVariants
				LibraryExtension: android.libraryVariants
				default: throw new GradleException('''Unknown packaging type «android.class.simpleName»''')
			}
			variants.all [ variant |
				xtext.sourceSets.maybeCreate(variant.name) => [ sourceSet |
					val sourceDirs = newArrayList
					val javaDirs = variant.sourceSets.map[javaDirectories].flatten.filter[directory]
					sourceDirs += javaDirs
					sourceDirs += #[
						variant.aidlCompile.sourceOutputDir,
						variant.generateBuildConfig.sourceOutputDir,
						variant.renderscriptCompile.sourceOutputDir
					]
					sourceDirs += variant.outputs.map[processResources.sourceOutputDir]
					sourceSet.srcDirs(sourceDirs)
				]
			]
		]
	}

}