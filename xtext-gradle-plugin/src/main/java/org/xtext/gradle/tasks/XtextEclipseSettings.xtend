package org.xtext.gradle.tasks;

import com.google.common.base.CharMatcher
import java.io.File
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.JavaVersion
import org.gradle.api.file.DirectoryProperty
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

	new() {
		outputs.upToDateWhen[false]
	}

	@OutputFiles
	def getOutputFiles() {
		languages.map [ language |
			prefsFor(language).location.toFile
		]
	}

	@TaskAction
	def writeSettings() {
		languages.forEach [ Language language |
			val prefs = prefsFor(language)
			prefs.load
			prefs.makeProjectSpecific
			prefs.addGeneratorPreferences(language)
			addValidatorPreferences(prefs, language)
			addAdditionalPreferences(prefs, language)
			prefs.save
		]
	}

	private def prefsFor(Language language) {
		new XtextEclipsePreferences(projectDirectory.get().asFile, language.qualifiedName.get)
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
		canonicalize(root.relativize(path).toString)
	}

	private def makeProjectSpecific(XtextEclipsePreferences prefs) {
		prefs.putBoolean("BuilderConfiguration.is_project_specific", true)
		prefs.putBoolean("ValidatorConfiguration.is_project_specific", true)
	}

	private def addGeneratorPreferences(XtextEclipsePreferences prefs, Language language) {
		language.generator => [
			prefs.putBoolean("generateSuppressWarnings", suppressWarningsAnnotation.get)
			prefs.putBoolean("generateGeneratedAnnotation", generatedAnnotation.active.get)
			prefs.putBoolean("includeDateInGenerated", generatedAnnotation.includeDate.get)
			if (generatedAnnotation.comment.present) {
				prefs.put("generatedAnnotationComment", generatedAnnotation.comment.get)
			}
			if (javaSourceLevel.present) {
				prefs.put("targetJavaVersion", "JAVA" + JavaVersion.toVersion(javaSourceLevel.get).majorVersion)
			}
			prefs.putBoolean("useJavaCompilerCompliance", false)
			outlets.forEach [ outlet |
				addOutletPreferences(prefs, language, outlet)
			]
		]
	}

	private def addOutletPreferences(XtextEclipsePreferences prefs, Language language, Outlet outlet) {
		sourceSets.forEach [
			srcDirs.forEach [ dir |
				prefs.put(
					outlet.getOutletKey("sourceFolder." + relativeToProject(dir) + ".directory"),
					relativeToProject(output.getDir(outlet))
				)
			]
		]
		prefs.putBoolean(
			outlet.getOutletKey("hideLocalSyntheticVariables"),
			language.debugger.hideSyntheticVariables.get
		)
		prefs.putBoolean(
			outlet.getOutletKey("installDslAsPrimarySource"),
			language.debugger.sourceInstaller.get == SourceInstaller.PRIMARY.name
		)
		prefs.putBoolean(
			outlet.getOutletKey("userOutputPerSourceFolder"),
			true
		)
	}

	private def addValidatorPreferences(XtextEclipsePreferences prefs, Language language) {
		language.validator.severities.get.entrySet.forEach [
			prefs.put(key, value.toString)
		]
	}

	private def addAdditionalPreferences(XtextEclipsePreferences prefs, Language language) {
		language.preferences.get.entrySet.forEach [
			prefs.put(key, value.toString)
		]
	}

	private def String getOutletKey(Outlet output, String preferenceName) '''outlet.«output.name».«preferenceName»'''

	private def canonicalize(String path) {
		CharMatcher.anyOf("/").trimTrailingFrom(path.replace('\\', '/'))
	}
}
