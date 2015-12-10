package org.xtext.gradle.tasks.internal

import java.io.File
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.gradle.api.Action
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextSourceDirectorySet

@FinalFieldsConstructor
class XtendSourceSet {
	val XtextSourceDirectorySet sources
	val Outlet xtendGen

	def void setXtendOutputDir(Object path) {
		sources.output.dir(xtendGen, path)
	}

	def File getXtendOutputDir() {
		sources.output.getDir(xtendGen)
	}

	def getXtend() {
		sources
	}

	def void xtend(Action<? super XtextSourceDirectorySet> action) {
		action.execute(sources)
	}
}