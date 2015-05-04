package org.xtext.gradle.idea.tasks

import com.google.common.base.Splitter
import groovy.lang.Closure
import java.io.File
import org.gradle.api.Project
import org.gradle.api.file.CopySpec
import org.gradle.api.file.FileCopyDetails
import com.google.common.io.Files

class GradleExtensions {
	static def copy(Project project, (CopySpec)=>void copyspec) {
		project.copy(new Closure(null) {
			override getMaximumNumberOfParameters() {
				1
			}

			override call(Object argument) {
				copyspec.apply(argument as CopySpec)
				null
			}
		})
	}
	
	static def /(File parent, String child) {
		new File(parent, child)
	}
	
	static def cutDirs(FileCopyDetails file, int levels) {
		val segments = Splitter.on('/').omitEmptyStrings.split(file.path)
		file.path = segments.drop(levels).join('/')
	}
	
	static def usingTmpDir((File)=>void action) {
		val tmp = Files.createTempDir
		try {
			action.apply(tmp)
		} finally {
			tmp.delete
		}
	}
}