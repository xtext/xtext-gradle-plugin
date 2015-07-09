package org.xtext.gradle.tasks.internal

import com.google.common.collect.ImmutableSet
import groovy.lang.Closure
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.Project
import org.gradle.api.internal.file.DefaultSourceDirectorySet
import org.gradle.api.internal.file.FileResolver
import org.gradle.api.internal.file.collections.DirectoryFileTree
import org.gradle.api.internal.file.collections.FileCollectionResolveContext
import org.gradle.util.ConfigureUtil
import org.xtext.gradle.tasks.XtextSourceSet
import org.xtext.gradle.tasks.XtextSourceSetOutputs

class DefaultXtextSourceSet extends DefaultSourceDirectorySet implements XtextSourceSet {
	@Accessors val XtextSourceSetOutputs output

	new(String name, Project project, FileResolver fileResolver) {
		super(name, fileResolver)
		output = new DefaultXtextSourceSetOutputs(project)
	}

	override output(Closure<?> configureAction) {
		ConfigureUtil.configure(configureAction, output)
	}

	override getGeneratorTaskName() {
		if (name == "main") {
			"generateXtext"
		} else {
			"generate" + name.toFirstUpper + "Xtext"
		}
	}

	override getSrcDirTrees() {
		val outputDirs = ImmutableSet.copyOf(output.dirs)
		super.srcDirTrees.filter[!outputDirs.contains(dir)].toSet
	}

	override resolve(FileCollectionResolveContext context) {
		for (directoryTree : srcDirTrees) {
			context.add((directoryTree as DirectoryFileTree).filter(filter));
		}
	}
}