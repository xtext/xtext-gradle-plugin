package org.xtext.gradle.idea.tasks

import com.google.common.base.Charsets
import com.google.common.io.Files
import java.io.File
import org.gradle.api.tasks.Sync
import org.gradle.api.tasks.Input
import org.eclipse.xtend.lib.annotations.Accessors

class IdeaRepository extends Sync {
	@Input @Accessors String rootUrl
	
	val files = <File>newArrayList
	
	new() {
		rootSpec.eachFile[files.add(file)]
	}
	
	override protected copy() {
		super.copy()
		val pluginDescriptor = new File(destinationDir, "updatePlugins.xml")
		Files.asCharSink(pluginDescriptor, Charsets.UTF_8).write('''
			<?xml version="1.0" encoding="UTF-8"?>
			<plugins>
				«FOR it : files»
					<plugin
						id="«name.substring(0, name.indexOf('-'))»"
						url="«rootUrl»/«name»"
						version="«name.substring(name.indexOf('-') + 1, name.lastIndexOf('.'))»"
					/>
				«ENDFOR»
			</plugins>
		''')
	}
}