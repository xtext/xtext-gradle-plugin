package org.xtext.gradle.tasks;

import de.oehme.xtend.contrib.Property
import java.io.File
import java.net.URLClassLoader
import java.util.ArrayList
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.TaskAction

import static extension org.xtext.gradle.GradleExtensions.*

class XtextGenerate extends DefaultTask {

	private XtextExtension xtext

	@Property @InputFiles FileCollection xtextClasspath

	@Property @InputFiles FileCollection classpath

	def configure(XtextExtension xtext) {
		this.xtext = xtext
		xtext.languages.forEach [ Language lang |
			lang.outputs.forEach [ OutputConfiguration output |
				outputs.dir(output.dir)
			]
		]
		inputs.source(xtext.sources)
	}

	@TaskAction
	def generate() {
		val args = newArrayList(
			"-encoding",
			xtext.getEncoding(),
			"-cwd",
			project.getProjectDir().absolutePath,
			"-classpath",
			getClasspath().asPath,
			"-tempdir",
			new File(project.buildDir, "xtext-temp").absolutePath
		)

		xtext.languages.forEach [ Language language |
			args += #[
				'''-L«language.name».setup=«language.setup»''',
				'''-L«language.name».javaSupport=«language.consumesJava»'''
			]
			language.outputs.forEach [ OutputConfiguration output |
				args += #[
					'''-L«language.name».«output.name».dir=«output.dir»''',
					'''-L«language.name».«output.name».createDir=true'''
				]
			]
		]
		args += xtext.sources.srcDirs.map[absolutePath]
		if (xtext.fork) {
			generateForked(args)
		} else {
			generateNonForked(args)
		}
	}

	def generateNonForked(ArrayList<String> arguments) {
		System.setProperty("org.eclipse.emf.common.util.ReferenceClearingQueue", "false")
		val contextClassLoader = Thread.currentThread.contextClassLoader
		val classLoader = new URLClassLoader(getXtextClasspath.map[absoluteFile.toURI.toURL],
			ClassLoader.systemClassLoader.parent)
		try {
			Thread.currentThread.contextClassLoader = classLoader
			val main = classLoader.loadClass("org.xtext.builder.standalone.Main")
			val mainMethod = main.getMethod("main",typeof(String[]))
			mainMethod.invoke(null, #[arguments as String[]])
		} finally {
			Thread.currentThread.contextClassLoader = contextClassLoader
		}
	}

	def generateForked(ArrayList<String> args) {
		val result = project.javaexec [
			main = "org.xtext.builder.standalone.Main"
			it.classpath = getXtextClasspath
			setArgs(args)
		]
		if (result.exitValue != 0) {
			throw new GradleException("Xtext failed");
		}
	}
}
