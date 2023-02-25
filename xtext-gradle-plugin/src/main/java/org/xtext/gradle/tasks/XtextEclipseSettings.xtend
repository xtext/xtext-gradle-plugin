package org.xtext.gradle.tasks;

import com.google.common.base.CharMatcher
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.JavaVersion
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.OutputFiles
import org.gradle.api.tasks.TaskAction
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller
import org.xtext.gradle.tasks.internal.XtextEclipsePreferences

class XtextEclipseSettings extends DefaultTask {

	@Accessors @Internal Set<XtextSourceDirectorySet> sourceSets
	@Accessors @Internal Set<Language> languages

	new() {
		outputs.upToDateWhen[false]
	}

	@OutputFiles
	def getOutputFiles() {
		languages.map [ language |
			val prefs = new XtextEclipsePreferences(project.projectDir, language.qualifiedName.get)
			prefs.location.toFile
		]
	}

	@TaskAction
	def writeSettings() {
		languages.forEach [ Language language |
			val prefs = new XtextEclipsePreferences(project.projectDir, language.qualifiedName.get)
			prefs.load
			prefs.makeProjectSpecific
			prefs.addGeneratorPreferences(language)
			addValidatorPreferences(prefs, language)
			addAdditionalPreferences(prefs, language)
			prefs.save
		]
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
					outlet.getOutletKey("sourceFolder." + project.relativePath(dir).canonicalize + ".directory"),
					project.relativePath(output.getDir(outlet)).canonicalize
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
