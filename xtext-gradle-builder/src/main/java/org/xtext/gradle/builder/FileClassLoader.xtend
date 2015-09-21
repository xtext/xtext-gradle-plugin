package org.xtext.gradle.builder

import com.google.common.collect.ImmutableList
import com.google.common.collect.Lists
import com.google.common.io.ByteStreams
import java.io.Closeable
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.net.MalformedURLException
import java.net.URL
import java.net.URLClassLoader
import java.net.URLConnection
import java.net.URLStreamHandler
import java.util.Collection
import java.util.List
import java.util.zip.ZipFile
import org.eclipse.emf.common.archive.ArchiveURLConnection
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory

//TODO move to Xtext
/** 
 * In contrast to {@link URLClassLoader}, this classloader does not use any
 * static caches for jars. Thus, the jar files can be deleted after this
 * classloader has been closed.
 */
class FileClassLoader extends ClassLoader implements Closeable {
	static val logger = LoggerFactory.getLogger(FileClassLoader)
	
	@Accessors
	val ImmutableList<File> files
	val List<ZipFile> archives
	val List<File> folders
	val List<InputStream> openStreams = newLinkedList
	boolean open = true

	new(Collection<File> files, ClassLoader parent) {
		super(parent)
		this.files = ImmutableList.copyOf(files)
		archives = Lists.newArrayListWithCapacity(files.size)
		folders = Lists.newArrayListWithCapacity(files.size)
		files.filter[exists].forEach [ file |
			if (file.name.endsWith(".jar")) {
				try {
					val zip = new ZipFile(file)
					archives.add(zip)
				} catch (IOException ioe) {
					logger.error("error reading zip file", ioe)
				}
			} else if (file.isDirectory) {
				folders.add(file)
			} else {
				logger.debug('''Ignored classpath entry «file» as it is neither a jar nor a folder''')
			}
		]
	}

	override synchronized void close() {
		if (!open)
			return;
		open = false
		for (stream : openStreams) {
			try {
				stream.close
			} catch (IOException ioe) {
				logger.debug("error closing stream", ioe)
			}

		}
		for (archive : archives) {
			try {
				archive.close
			} catch (IOException ioe) {
				logger.debug("error closing zip file", ioe)
			}

		}
	}

	override protected synchronized findClass(String name) throws ClassNotFoundException {
		val classData = loadClassData(name)
		if (classData === null) {
			throw new ClassNotFoundException('''Could not find class «name»''')
		}
		val clazz = defineClass(name, classData, 0, classData.length)
		val pkgName = getPackageName(name)
		if (pkgName !== null) {
			val pkg = getPackage(pkgName)
			if (pkg === null) {
				definePackage(pkgName, null, null, null, null, null, null, null)
			}
		}
		return clazz
	}

	def private getPackageName(String fullyQualifiedName) {
		val index = fullyQualifiedName.lastIndexOf(Character.valueOf('.'))
		if (index !== -1) {
			return fullyQualifiedName.substring(0, index)
		}
		return null
	}

	def private loadClassData(String name) {
		val path = name.replace(Character.valueOf('.'), Character.valueOf('/'))
		val input = getResourceAsStream('''«path».class''')
		if (input === null)
			return null
		try {
			return ByteStreams.toByteArray(input)
		} catch (IOException ioe) {
			logger.error("error reading class file", ioe)
			return null
		} finally {
			try {
				input.close()
			} catch (IOException ioe) {
				logger.debug("error closing class file", ioe)
			}

		}
	}

	override synchronized getResource(String name) {
		val resource = parent.getResource(name)
		if (resource !== null) {
			return resource
		}
		if (!open) {
			return null
		}
		for (folder : folders) {
			val child = new File(folder, name)
			if (child.exists) {
				try {
					return child.toURL
				} catch (MalformedURLException e) {
					logger.error('''error accessing resource «name»''', e)
				}
			}
		}
		for (archive : archives) {
			val entry = archive.getEntry(name)
			if (entry !== null) {
				try {
					val handler = new ArchiveURLStreamHandler(openStreams)
					return new URL(null, '''archive:file:///«archive.name»!/«entry.name»''', handler)
				} catch (MalformedURLException e) {
					logger.error('''error accessing resource «name»''', e)
				}
			}
		}
		return null
	}

	/** 
	 * Using jar URLs causes the jars to be put in a static cache, unable to be closed and deleted. 
	 * We avoid this by using archive URLs instead.
	 */
	@FinalFieldsConstructor
	private static final class ArchiveURLStreamHandler extends URLStreamHandler {
		val List<InputStream> openStreams

		override protected URLConnection openConnection(URL url) throws IOException {
			return new ArchiveURLConnection(url) {
				override protected InputStream createInputStream(String nestedURL) throws IOException {
					val stream = super.createInputStream(nestedURL)
					openStreams.add(stream)
					return stream
				}
			}
		}
	}

	override getResources(String name) throws IOException {
		throw new UnsupportedOperationException("getResources() not implemented")
	}
}