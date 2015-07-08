package org.xtext.gradle.tasks

import groovy.lang.Closure
import org.gradle.api.file.SourceDirectorySet

interface XtextSourceSet extends SourceDirectorySet {
	def XtextSourceSetOutputs getOutput()
	def void output(Closure<?> configureClosure)
	def String getGeneratorTaskName()
}