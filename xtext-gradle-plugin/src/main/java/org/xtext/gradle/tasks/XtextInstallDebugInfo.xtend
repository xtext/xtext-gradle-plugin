package org.xtext.gradle.tasks;

import java.io.File
import java.util.Set
import org.gradle.api.DefaultTask
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.provider.Property
import org.gradle.api.provider.SetProperty
import org.gradle.api.tasks.Classpath
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.TaskAction
import org.gradle.work.DisableCachingByDefault
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.GradleSourceInstallerConfig
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.internal.IncrementalXtextBuilderProvider

/**
 * Installs debug information into already-compiled classes for the sources produced
 * by the Xtext generators.
 *
 * This used to be a {@code javaCompile.doLast} action that captured the generator task
 * and called back into it. A task's action cannot reference another task under the
 * configuration cache - the cache serializes each task independently - so this is a
 * real task with values-only inputs, ordered after compilation.
 */
@DisableCachingByDefault(because = "Writes bytecode instrumentation into classes produced by another task; it must run in the same build as that task.")
abstract class XtextInstallDebugInfo extends DefaultTask {

	@Internal abstract def SetProperty<Language> getLanguages()

	@Internal abstract def ConfigurableFileCollection getGeneratedSourceDirs()

	@Internal abstract def Property<Boolean> getHasXtextSources()

	@Input abstract def Property<String> getEncoding()

	@Classpath abstract def ConfigurableFileCollection getXtextClasspath()

	/**
	 * Not an output: this directory is produced by the Java compile task. Declaring it
	 * here would make two tasks claim the same output, which Gradle 9 rejects as an
	 * implicit cross-task dependency. This task only rewrites class files in place.
	 */
	@Internal abstract def DirectoryProperty getClassesDir()

	@TaskAction
	def installDebugInfo() {
		if (!hasXtextSources.get()) {
			return
		}
		val builder = IncrementalXtextBuilderProvider.getBuilder(
			languages.get().map[setup.get].toSet, encoding.get,
			(xtextClasspath.files + #[IncrementalXtextBuilderProvider.builderJar]).toSet)
		val generatedFiles = generatedSourceDirs.files.toList
		val request = new GradleInstallDebugInfoRequest => [
			generatedJavaFiles = generatedFiles.filter[name.endsWith(".java")].toSet
			it.classesDir = this.classesDir.get().asFile
			sourceInstallerByFileExtension = newLinkedHashMap

			languages.get().forEach [ lang |
				lang.fileExtensions.get.forEach [ ext |
					sourceInstallerByFileExtension.put(ext, new GradleSourceInstallerConfig() => [
						sourceInstaller = SourceInstaller.valueOf(lang.debugger.sourceInstaller.get)
						hideSyntheticVariables = lang.debugger.hideSyntheticVariables.get
					])
				]

			]
		]
		builder.installDebugInfo(request)
	}
}
