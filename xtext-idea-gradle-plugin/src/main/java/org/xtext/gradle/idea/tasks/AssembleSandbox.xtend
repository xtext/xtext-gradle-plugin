package org.xtext.gradle.idea.tasks

import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.file.CopySpec
import org.gradle.api.tasks.Sync

@Accessors
class AssembleSandbox extends Sync implements IdeaPluginSpec {
	CopySpec plugin
	CopySpec classes
	CopySpec libraries
	CopySpec metaInf
	

	new() {
		val plugin = rootSpec.addChild
		this.plugin = plugin
		classes = plugin.addChild.into("classes")
		libraries = plugin.addChild.into("lib")
		metaInf = plugin.addChild.into("META-INF")
	}
}