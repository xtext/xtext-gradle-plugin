package org.xtext.gradle.tasks.internal

import java.io.File
import org.eclipse.xtend.lib.annotations.Delegate
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.xtext.gradle.tasks.Outlet
import org.xtext.gradle.tasks.XtextSourceDirectorySet

@FinalFieldsConstructor
class XtendSourceDirectorySet implements XtextSourceDirectorySet {
	@Delegate
	val XtextSourceDirectorySet delegate

	val Outlet xtendGen

	def void setOutputDir(Object path) {
		delegate.output.dir(xtendGen, path)
	}

	def File getOutputDir() {
		delegate.output.getDir(xtendGen)
	}
}
