package org.xtext.gradle.tasks.internal

import groovy.lang.Closure
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Delegate
import org.gradle.api.Project
import org.gradle.api.file.SourceDirectorySet
import org.gradle.api.internal.file.DefaultSourceDirectorySet
import org.gradle.api.internal.file.FileResolver
import org.gradle.internal.reflect.Instantiator
import org.gradle.util.ConfigureUtil
import org.xtext.gradle.tasks.XtextSourceSet
import org.xtext.gradle.tasks.XtextSourceSetOutputs

@Accessors
class DefaultXtextSourceSet implements XtextSourceSet {
	val String name
	@Delegate val SourceDirectorySet sources
	val XtextSourceSetOutputs output

	new(String name, Project project, FileResolver fileResolver, Instantiator instantiator) {
		this.name = name
		output = new DefaultXtextSourceSetOutputs(project, instantiator)
		sources = new DefaultSourceDirectorySet(name + " Xtext sources", fileResolver)
	}

	override output(Closure<?> configureAction) {
		ConfigureUtil.configure(configureAction, output)
	}

	override getSrcDirTrees() {
		sources.srcDirTrees.filter[!output.dirs.contains(dir)].toSet
	}

	override getGeneratorTaskName() {
		if (name == "main") {
			"generateXtext"
		} else {
			"generate" + name.toFirstUpper + "Xtext"
		}
	}

}