package org.xtext.gradle.tasks;

import org.gradle.api.file.FileCollection;

public interface XtextClasspathInferrer {

	public FileCollection inferXtextClasspath(XtextSourceDirectorySet sourceSet, FileCollection xtextClasspath, FileCollection classpath);
}
