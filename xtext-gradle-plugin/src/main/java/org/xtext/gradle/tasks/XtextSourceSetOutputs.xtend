package org.xtext.gradle.tasks

import org.gradle.api.file.FileCollection
import java.io.File

interface XtextSourceSetOutputs {
	def FileCollection getDirs()
	def File getDir(Outlet outlet)
	def void dir(Outlet outlet, Object path)
}