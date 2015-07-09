package org.xtext.gradle.builder;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.net.URLConnection;
import java.net.URLStreamHandler;
import java.util.Collection;
import java.util.Enumeration;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import org.eclipse.emf.common.archive.ArchiveURLConnection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Lists;
import com.google.common.io.ByteStreams;

/**
 * In contrast to {@link URLClassLoader}, this classloader does not use any
 * static caches for jars. Thus, the jar files can be deleted after this
 * classloader has been closed.
 */
public class FileClassLoader extends ClassLoader {
	

	private static final Logger logger = LoggerFactory.getLogger(FileClassLoader.class);

	private final ImmutableList<File> files;
	private final List<ZipFile> archives;
	private final List<File> folders;
	
	private final List<InputStream> openStreams = Lists.newLinkedList();
	private boolean open = true;

	public FileClassLoader(Collection<File> files, ClassLoader parent) {
		super(parent);
		this.files = ImmutableList.copyOf(files);
		archives = Lists.newArrayListWithCapacity(files.size());
		folders = Lists.newArrayListWithCapacity(files.size());
		for (File file : files) {
			if (file.exists()) {
				if (file.getName().endsWith(".jar")) {
					try {
						ZipFile zip = new ZipFile(file);
						archives.add(zip);
					} catch (IOException ioe) {
						logger.error("error reading zip file", ioe);
					}
				} else if (file.isDirectory()){
					folders.add(file);
				} else {
					throw new IllegalArgumentException("This classloader only supports jars and directories");
				}
			}
		}
	}

	public List<File> getFiles() {
		return files;
	}
	
	public synchronized void close() {
		if (!open)
			return;
		open = false;

		for (InputStream stream : openStreams) {
			try {
				stream.close();
			} catch (IOException ioe) {
				logger.debug("error closing stream", ioe);
			}
		}

		for (ZipFile archive : archives) {
			try {
				archive.close();
			} catch (IOException ioe) {
				logger.debug("error closing zip file", ioe);
			}
		}
	}

	@Override
	protected synchronized Class<?> findClass(String name) throws ClassNotFoundException {
		byte[] classData = loadClassData(name);
		if (classData == null) {
			throw new ClassNotFoundException("Could not find class " + name);
		}
		Class<?> clazz = defineClass(name, classData, 0, classData.length);
		String pkgName = getPackageName(name);
		if (pkgName != null) {
			Package pkg = getPackage(pkgName);
			if (pkg == null) {
				definePackage(pkgName, null, null, null, null, null, null, null);
			}
		}
		return clazz;
	}

	private String getPackageName(String fullyQualifiedName) {
		int index = fullyQualifiedName.lastIndexOf('.');
		if (index != -1) {
			return fullyQualifiedName.substring(0, index);
		}
		return null;
	}

	private byte[] loadClassData(String name) {
		String path = name.replace('.', '/');
		InputStream input = getResourceAsStream(path + ".class");
		if (input == null)
			return null;
		try {
			return ByteStreams.toByteArray(input);
		} catch (IOException ioe) {
			logger.error("error reading class file", ioe);
			return null;
		} finally {
			try {
				input.close();
			} catch (IOException ioe) {
				logger.debug("error closing class file", ioe);
			}
		}
	}

	@Override
	public synchronized URL getResource(String name) {
		URL resource = getParent().getResource(name);
		if (resource != null) {
			return resource;
		}
		if (!open) {
			return null;
		}
		for (File folder : folders) {
			File child = new File(folder, name);
			if (child.exists()) {
				try {
					return child.toURL();
				} catch (MalformedURLException e) {
					logger.error("error accessing resource " + name, e);
				}
			}
		}
		for (ZipFile archive : archives) {
			ZipEntry entry = archive.getEntry(name);
			if (entry != null) {
				try {
					URLStreamHandler handler = new ArchiveURLStreamHandler();
					return new URL(null, "archive:file:///" + archive.getName() + "!/" + entry.getName(), handler);
				} catch (MalformedURLException e) {
					logger.error("error accessing resource " + name, e);
				}
			}
		}
		return null;
	}
	
	/**
	 * Using jar URLs causes the jars to be put in a static cache, unable to be closed and deleted. 
	 * We avoid this by using archive URLs instead.
	 */
	private final class ArchiveURLStreamHandler extends URLStreamHandler {
		@Override
		protected URLConnection openConnection(URL url) throws IOException {
			return new ArchiveURLConnection(url);
		}
	}

	@Override
	public Enumeration<URL> getResources(String name) throws IOException {
		throw new UnsupportedOperationException("getResources() not implemented");
	}

}
