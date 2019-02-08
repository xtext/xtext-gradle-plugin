package org.xtext.gradle.tasks

import groovy.lang.Closure
import java.io.File
import java.util.Set
import org.gradle.api.file.FileTree
import org.gradle.api.tasks.util.PatternFilterable
import org.gradle.api.Action

interface XtextSourceDirectorySet extends PatternFilterable {

	def String getName()

	def XtextSourceDirectorySet srcDir(Object srcPath)

	def XtextSourceDirectorySet srcDirs(Object... srcPaths)

	def Set<File> getSrcDirs()

	def XtextSourceDirectorySet setSrcDirs(Iterable<?> srcPaths)

	def FileTree getFiles()

	def PatternFilterable getFilter()

	def XtextSourceSetOutputs getOutput()

	def void output(Closure<?> configureClosure)
	
	def void output(Action<XtextSourceSetOutputs> action)

	def String getGeneratorTaskName()

	def String qualifyConfigurationName(String prefix) {
		prefix + name.toFirstUpper
	}
}