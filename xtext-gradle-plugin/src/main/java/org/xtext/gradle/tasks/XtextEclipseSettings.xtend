package org.xtext.gradle.tasks;

import com.google.common.base.CharMatcher
import java.io.File
import java.util.Map
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.JavaVersion
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.OutputFiles
import org.gradle.api.tasks.TaskAction
import org.gradle.work.DisableCachingByDefault
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.internal.XtextEclipsePreferences

@DisableCachingByDefault(because = "Merges into user-owned, version-controlled .settings files that are not reproducible build outputs.")
abstract class XtextEclipseSettings extends DefaultTask {

	@Accessors @Internal Set<XtextSourceDirectorySet> sourceSets
	@Accessors @Internal Set<Language> languages

	/** Set at configuration time: Task.getProject() is an error in Gradle 10. */
	@Internal abstract def DirectoryProperty getProjectDirectory()

	@Input
	def Map<String, Map<String, String>> getEffectivePreferences() {
		languages.toMap[qualifiedName.get].mapValues [ language |
			val result = newLinkedHashMap
			collectPreferences(result, language)
			result
		]
	}

	@OutputFiles
	def getOutputFiles() {
		languages.map [ language |
			new XtextEclipsePreferences(projectDirectory.get().asFile, language.qualifiedName.get).location.toFile
		]
	}

	@TaskAction
	def writeSettings() {
		effectivePreferences.forEach [ qualifiedName, preferences |
			val prefs = new XtextEclipsePreferences(projectDirectory.get().asFile, qualifiedName)
			prefs.load
			preferences.forEach [ key, value |
				prefs.put(key, value)
			]
			prefs.save
		]
	}

	/**
	 * Path of the given file relative to the project directory.
	 *
	 * Deliberately lexical: Path.normalize() removes "." and ".." segments without
	 * touching the filesystem, whereas File.canonicalFile resolves symbolic links.
	 * Resolving them would rewrite a source folder that is a link to somewhere else
	 * (src/main/xtend -> ../shared-sources) to its target, and Eclipse would then be
	 * configured with a folder the build never declared.
	 */
	private def String relativeToProject(File file) {
		val root = projectDirectory.get().asFile.toPath.toAbsolutePath.normalize()
		val path = file.toPath.toAbsolutePath.normalize()
		try {
			canonicalize(root.relativize(path).toString)
		} catch (IllegalArgumentException e) {
			// Different filesystem roots (e.g. buildDir on another Windows drive):
			// no relative path exists, keep the normalized absolute one.
			canonicalize(path.toString)
		}
	}

	private def collectPreferences(Map<String, String> result, Language language) {
		result.put("BuilderConfiguration.is_project_specific", "true")
		result.put("ValidatorConfiguration.is_project_specific", "true")
		language.generator => [
			result.put("generateSuppressWarnings", suppressWarningsAnnotation.get.toString)
			result.put("generateGeneratedAnnotation", generatedAnnotation.active.get.toString)
			result.put("includeDateInGenerated", generatedAnnotation.includeDate.get.toString)
			if (generatedAnnotation.comment.present) {
				result.put("generatedAnnotationComment", generatedAnnotation.comment.get)
			}
			if (javaSourceLevel.present) {
				result.put("targetJavaVersion", "JAVA" + JavaVersion.toVersion(javaSourceLevel.get).majorVersion)
			}
			result.put("useJavaCompilerCompliance", "false")
			outlets.forEach [ outlet |
				sourceSets.forEach [
					srcDirs.forEach [ dir |
						result.put(
							outlet.getOutletKey("sourceFolder." + relativeToProject(dir) + ".directory"),
							relativeToProject(output.getDir(outlet))
						)
					]
				]
				result.put(
					outlet.getOutletKey("hideLocalSyntheticVariables"),
					language.debugger.hideSyntheticVariables.get.toString
				)
				result.put(
					outlet.getOutletKey("installDslAsPrimarySource"),
					(language.debugger.sourceInstaller.get == SourceInstaller.PRIMARY.name).toString
				)
				result.put(
					outlet.getOutletKey("userOutputPerSourceFolder"),
					"true"
				)
			]
		]
		language.validator.severities.get.entrySet.forEach [
			result.put(key, value.toString)
		]
		language.preferences.get.entrySet.forEach [
			result.put(key, value.toString)
		]
	}

	private def String getOutletKey(Outlet output, String preferenceName) '''outlet.«output.name».«preferenceName»'''

	private def canonicalize(String path) {
		CharMatcher.anyOf("/").trimTrailingFrom(path.replace('\\', '/'))
	}
}
