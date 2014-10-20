package org.xtext.gradle.tasks;

import java.io.File
import java.net.URLClassLoader
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.TaskAction
import org.gradle.internal.classloader.FilteringClassLoader

class XtextGenerate extends DefaultTask {

	private XtextExtension xtext

	@Accessors @InputFiles FileCollection xtextClasspath

	@Accessors @InputFiles FileCollection classpath

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
		generate(args)
	}

	def generate(List<String> arguments) {
		System.setProperty("org.eclipse.emf.common.util.ReferenceClearingQueue", "false")
		val contextClassLoader = Thread.currentThread.contextClassLoader
		val classLoader = getCompilerClassLoader(getXtextClasspath)
		try {
			Thread.currentThread.contextClassLoader = classLoader
			val main = classLoader.loadClass("org.xtext.builder.standalone.Main")
			val method = main.getMethod("generate", typeof(String[]))
			val success = method.invoke(null, #[arguments as String[]]) as Boolean
			if (!success) {
				throw new GradleException('''Xtext generation failed''');
			}
		} finally {
			Thread.currentThread.contextClassLoader = contextClassLoader
		}
	}

	static val currentCompilerClassLoader = new ThreadLocal<URLClassLoader>() {
		override protected initialValue() {
			null
		}
	}

	private def getCompilerClassLoader(FileCollection classpath) {
		val classPathWithoutLog4j = classpath.filter[!name.contains("log4j")]
		val urls = classPathWithoutLog4j.map[absoluteFile.toURI.toURL].toList
		val currentClassLoader = currentCompilerClassLoader.get
		if (currentClassLoader !== null && currentClassLoader.URLs.toList == urls) {
			return currentClassLoader
		} else {
			val newClassLoader = new URLClassLoader(urls, loggingBridgeClassLoader)
			currentCompilerClassLoader.set(newClassLoader)
			return newClassLoader
		}
	}

	private def loggingBridgeClassLoader() {
		new FilteringClassLoader(XtextGenerate.classLoader) => [
			allowPackage("org.slf4j")
			allowPackage("org.apache.log4j")
		]
	}
}
