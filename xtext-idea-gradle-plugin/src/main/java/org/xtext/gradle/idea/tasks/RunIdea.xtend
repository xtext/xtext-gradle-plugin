package org.xtext.gradle.idea.tasks

import com.google.common.collect.Lists
import java.io.File
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.JavaExec
import org.gradle.api.internal.tasks.options.Option
import static extension org.xtext.gradle.idea.tasks.GradleExtensions.*

@Accessors
class RunIdea extends JavaExec {
	@Input File sandboxDir
	@Input File ideaHome
	@Input boolean debugBuilder

	new() {
		main = "com.intellij.idea.Main"
		maxHeapSize = "2G"
		jvmArgs("-XX:MaxPermSize=512m")
	}

	override getJvmArgs() {
		val args = Lists.newArrayList(super.jvmArgs)
		args += '''-ea'''
		args += '''-Didea.home.path=«ideaHome»'''
		args += '''-Didea.plugins.path=«sandboxDir»'''
		if (debugBuilder) {
			args += '''-Dcompiler.process.debug.port=5005'''
		}
		args
	}
	
	@Option(option = "debug-builder", description = "Starts Idea's external builder process in debugging mode on port 5005")
	def setDebugBuilder(boolean debugBuilder) {
		this.debugBuilder = debugBuilder
	}
}
