package org.xtext.gradle.tasks

import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.file.FileCollection
import java.io.File
import org.gradle.api.Named

interface XtextSourceSetOutputs extends NamedDomainObjectContainer<LanguageSourceSetOutputs> {
	def FileCollection getDirs()
}

interface LanguageSourceSetOutputs extends NamedDomainObjectContainer<LanguageSourceSetOutput>, Named {
	def FileCollection getDirs()
}

interface LanguageSourceSetOutput extends Named {
	def File getDir()

	def void setDir(Object dir)

	def boolean isProducesJava()

	def void setProducesJava(boolean producesJava)

	def boolean isHideSyntheticVariables()

	def void setHideSyntheticVariables(boolean hideSyntheticVariables)

	def SourceInstaller getSourceInstaller()

	def void setSourceInstaller(SourceInstaller sourceInstaller)
}

enum SourceInstaller {
	PRIMARY,
	SMAP,
	NONE
}