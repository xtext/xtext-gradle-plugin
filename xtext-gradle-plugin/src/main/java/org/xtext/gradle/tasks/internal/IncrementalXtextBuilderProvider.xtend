package org.xtext.gradle.tasks.internal

import com.google.common.io.Files
import com.google.common.io.Resources
import java.io.Closeable
import java.io.File
import java.net.URLClassLoader
import java.util.ServiceLoader
import java.util.Set
import org.xtext.gradle.protocol.IncrementalXtextBuilder
import org.xtext.gradle.protocol.IncrementalXtextBuilderFactory

class IncrementalXtextBuilderProvider {
	static IncrementalXtextBuilder builder
	static long builderChecksum
	static Object lock = new Object

	/**
	 * The bundled generator, extracted to a temp file so it can be put on an isolated
	 * classloader. Shared by XtextGenerate and XtextInstallDebugInfo.
	 */
	static File extractedBuilderJar

	static def File getBuilderJar() {
		synchronized(lock) {
			if (extractedBuilderJar === null) {
				val jar = File.createTempFile("xtext-gradle-builder", "jar")
				jar.deleteOnExit
				Resources.asByteSource(
					typeof(IncrementalXtextBuilderProvider).classLoader.getResource("xtext-gradle-builder.jar")).copyTo(
					Files.asByteSink(jar))
				extractedBuilderJar = jar
			}
			return extractedBuilderJar
		}
	}

	static def IncrementalXtextBuilder getBuilder(Set<String> languageSetups, String encoding,
		Set<File> xtextClasspath) {
		synchronized (lock) {
			if (incompatibleBuilderExists(languageSetups, encoding, xtextClasspath)) {
				closeBuilder
			}
			if (builder === null) {
				createBuilder(languageSetups, encoding, xtextClasspath)
			}
			return builder;
		}
	}

	private static def incompatibleBuilderExists(Set<String> languageSetups, String encoding,
		Set<File> xtextClasspath) {
		builder !== null && getCheckSum(languageSetups, encoding, xtextClasspath) != builderChecksum
	}

	private static def closeBuilder() {
		(builder.class.classLoader as Closeable).close
		builder = null
	}

	private static def void createBuilder(Set<String> languageSetups, String encoding, Set<File> xtextClasspath) {
		val loader = ServiceLoader.load(IncrementalXtextBuilderFactory, getBuilderClassLoader(xtextClasspath))
		val providers = loader.iterator();
		if (providers.hasNext()) {
			builder = providers.next().get(languageSetups, encoding);
			builderChecksum = getCheckSum(languageSetups, encoding, xtextClasspath)
		} else {
			throw new IllegalStateException('''No «IncrementalXtextBuilderFactory.name» found on the classpath''');
		}
	}

	private static def getBuilderClassLoader(Set<File> xtextClasspath) {
		val parent = IncrementalXtextBuilderProvider.classLoader
		val filtered = new FilteringClassLoader(parent,
			#["org.gradle", "org.apache.log4j", "org.slf4j", "org.xtext.gradle"])
		new URLClassLoader(xtextClasspath.map[toURI.toURL], filtered)
	}

	private static def long getCheckSum(Set<String> languageSetups, String encoding, Set<File> xtextClasspath) {
		var long hash = 0
		for (setup : languageSetups) {
			hash = setup.hashCode + hash * 31
		}
		hash = encoding.hashCode + hash * 31
		for (classpathEntry : xtextClasspath) {
			hash = classpathEntry.path.hashCode + classpathEntry.lastModified.hashCode + hash * 31
		}
		hash
	}

}
