package org.xtext.gradle.android

import com.android.build.gradle.AppExtension
import com.android.build.gradle.AppPlugin
import com.android.build.gradle.BaseExtension
import com.android.build.gradle.LibraryExtension
import com.android.build.gradle.LibraryPlugin
import com.android.build.gradle.api.BaseVariant
import com.android.build.gradle.internal.api.TestedVariant
import java.io.File
import org.gradle.api.DomainObjectSet
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.xtext.gradle.XtextBuilderPlugin
import org.xtext.gradle.XtextJavaLanguagePlugin
import org.xtext.gradle.tasks.XtextExtension
import org.xtext.gradle.tasks.XtextGenerate

class XtextAndroidBuilderPlugin implements Plugin<Project> {

	Project project
	XtextExtension xtext
	BaseExtension android
	DomainObjectSet<? extends BaseVariant> variants

	override apply(Project project) {
		this.project = project
		project.apply[
			plugin(XtextBuilderPlugin)
			plugin(XtextJavaLanguagePlugin)
		]
		xtext = project.extensions.getByType(XtextExtension)
		project.plugins.withType(AppPlugin)[configureAndroid]
		project.plugins.withType(LibraryPlugin)[configureAndroid]
	}

	private def configureAndroid() {
		project.afterEvaluate[
			android = project.extensions.getByName("android") as BaseExtension
			variants = switch android {
				AppExtension: android.applicationVariants as DomainObjectSet<? extends BaseVariant>
				LibraryExtension: android.libraryVariants
				default: throw new GradleException('''Unknown packaging type «android.class.simpleName»''')
			}
			configureOutletDefaults
			configureGeneratorDefaults
			configureSourceSetDefaults
		]
	}

	private def configureSourceSetDefaults() {
		variants.all [ variant |
			configureSourceSetForVariant(variant)
			if (variant instanceof TestedVariant) {
				if (variant.testVariant != null)
					configureSourceSetForVariant(variant.testVariant)
			}
		]
	}
	
	private def configureSourceSetForVariant(BaseVariant variant) {
		xtext.sourceSets.maybeCreate(variant.name) => [ sourceSet |
			val generatorTask = project.tasks.getByName(sourceSet.generatorTaskName) as XtextGenerate
			generatorTask.dependsOn(
				variant.aidlCompile,
				variant.renderscriptCompile,
				variant.generateBuildConfig
			)
			generatorTask.dependsOn(variant.outputs.map[processResources])
			variant.javaCompiler.doLast[generatorTask.installDebugInfo]
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
			generatorTask.bootClasspath = android.bootClasspath.join(File.pathSeparator)
			generatorTask.classpath = variant.javaCompiler.classpath.plus(project.files(android.bootClasspath))
			generatorTask.classesDir = variant.javaCompiler.destinationDir
			generatorTask.options.encoding = android.compileOptions.encoding
			variant.registerJavaGeneratingTask(generatorTask, generatorTask.outputDirectories)
		]
	}

	private def configureGeneratorDefaults() {
		xtext.languages.all [
			generator.javaSourceLevel = android.compileOptions.sourceCompatibility.toString
		]
	}

	private def configureOutletDefaults() {
		xtext.languages.all [ language |
			language.generator.outlets.all [ outlet |
				xtext.sourceSets.all [ sourceSet |
					val output = sourceSet.output
					output.dir(outlet, '''«project.buildDir»/generated/source/«language.name»«outlet.folderFragment»/«sourceSet.name»''')
				]
			]
		]
	}

}