package org.xtext.gradle.tasks;

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.TaskAction

class XtextGenerate extends DefaultTask {

	private XtextExtension xtext

	def configure(XtextExtension xtext) {
		this.xtext = xtext
		xtext.languages.each {Language lang ->
			lang.outputs.each {  OutputConfiguration output ->
				this.outputs.dir(output.dir)
			}
		}
		inputs.source(xtext.sources)
	}

	@TaskAction
	def generate() {
		println("Xtext generating...")
		xtext.languages.each {Language lang ->
			lang.outputs.each {  OutputConfiguration output ->
				def dir = project.file(output.dir)
				dir.mkdirs()
				def file = new File(dir, "output.txt")
				file.createNewFile()
				file.write("Foo")
			}
		}
	}
}
