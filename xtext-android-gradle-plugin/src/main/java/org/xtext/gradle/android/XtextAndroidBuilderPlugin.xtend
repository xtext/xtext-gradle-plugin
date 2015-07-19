package org.xtext.gradle.android

import com.android.build.gradle.AppExtension
import com.android.build.gradle.AppPlugin
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.LibraryExtension
import com.android.build.gradle.LibraryPlugin
import com.android.build.gradle.api.BaseVariant
import com.google.common.base.CaseFormat
import java.io.File
import org.gradle.api.DomainObjectSet
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.xtext.gradle.XtextBuilderPlugin
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate
import org.xtext.gradle.tasks.XtextSourceSetOutputs

import static extension org.xtext.gradle.GradleExtensions.*

class XtextAndroidBuilderPlugin implements Plugin<Project> {

	Project project
	XtextExtension xtext
	BaseExtension android
	DomainObjectSet<? extends BaseVariant> variants

	override apply(Project project) {
		this.project = project
		project.plugins.<XtextBuilderPlugin>apply(XtextBuilderPlugin)
		xtext = project.extensions.getByType(XtextExtension)
		project.plugins.withType(AppPlugin)[configureAndroid]
		project.plugins.withType(LibraryPlugin)[configureAndroid]
	}

	private def configureAndroid() {
		android = project.extensions.getByName("android") as BaseExtension
		variants = switch android {
			AppExtension: android.applicationVariants
			LibraryExtension: android.libraryVariants
			default: throw new GradleException('''Unknown packaging type «android.class.simpleName»''')
		}
		configureSourceSetDefaults
		configureGeneratorDefaults
		configureOutletDefaults
	}

	private def configureSourceSetDefaults() {
		variants.all [ variant |
			xtext.sourceSets.maybeCreate(variant.name) => [ sourceSet |
				val lazySourceDirs = project.lazyFileCollection[
					val sourceDirs = newArrayList
					val javaDirs = variant.sourceSets.map[javaDirectories].flatten.filter[directory]
					sourceDirs += javaDirs
					sourceDirs += #[
						variant.aidlCompile.sourceOutputDir,
						variant.generateBuildConfig.sourceOutputDir,
						variant.renderscriptCompile.sourceOutputDir
					]
					sourceDirs += variant.outputs.map[processResources.sourceOutputDir]	
				]
				sourceSet.srcDirs(lazySourceDirs)
				
				val generatorTask = project.tasks.getByName(sourceSet.generatorTaskName) as XtextGenerate
				generatorTask.dependsOn(
					variant.aidlCompile,
					variant.renderscriptCompile,
					variant.generateBuildConfig
				)
				generatorTask.dependsOn(variant.outputs.map[processResources])
				variant.javaCompiler.doLast[generatorTask.installDebugInfo]
				project.afterEvaluate[
					generatorTask.bootClasspath = android.bootClasspath.join(File.pathSeparator)
					generatorTask.classpath = variant.javaCompiler.classpath
					generatorTask.classesDir = variant.javaCompiler.destinationDir
					variant.registerJavaGeneratingTask(generatorTask, generatorTask.outputDirectories)
				]
			]
		]
	}

	private def configureGeneratorDefaults() {
		project.afterEvaluate[
			xtext.languages.all [
				generator.javaSourceLevel = android.compileOptions.sourceCompatibility.toString
			]
		]
	}

	private def configureOutletDefaults() {
		xtext.languages.all [ language |
			language.generator.outlets.all [ outlet |
				xtext.sourceSets.all [ sourceSet |
					val outletFragment = if (outlet.name == Outlet.DEFAULT_OUTLET) {
							""
						} else {
							CaseFormat.LOWER_UNDERSCORE.to(CaseFormat.UPPER_CAMEL, outlet.name)
						}
					val output = sourceSet.output as XtextSourceSetOutputs
					output.dir(outlet, '''«project.buildDir»/generated/source/«outletFragment»/«sourceSet.name»''')
				]
			]
		]
	}
}