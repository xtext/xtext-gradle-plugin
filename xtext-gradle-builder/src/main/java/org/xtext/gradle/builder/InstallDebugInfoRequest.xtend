package org.xtext.gradle.builder

import java.io.File
import java.util.Collection
import java.util.Map
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtend.lib.annotations.Accessors

//TODO move to Xtext
@Accessors
class InstallDebugInfoRequest {
	Collection<File> generatedJavaFiles = newArrayList
	File classesDir
	File outputDir
	Map<String, SourceInstallerConfig> sourceInstallerByFileExtension = newHashMap
	ResourceSet resourceSet

	@Accessors
	static class SourceInstallerConfig {
		boolean hideSyntheticVariables
		SourceInstaller sourceInstaller
	}

	static enum SourceInstaller {
		PRIMARY,
		SMAP,
		NONE
	}
}
