package org.xtext.gradle.builder

import com.google.common.io.Files
import com.google.inject.Inject
import com.google.inject.Provider
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.generator.trace.AbstractTraceRegion
import org.eclipse.xtext.generator.trace.SourceRelativeURI
import org.eclipse.xtext.generator.trace.TraceAsPrimarySourceInstaller
import org.eclipse.xtext.generator.trace.TraceFileNameProvider
import org.eclipse.xtext.generator.trace.TraceRegionSerializer
import org.eclipse.xtext.generator.trace.TraceAsSmapInstaller
import org.slf4j.LoggerFactory
import org.xtext.gradle.builder.InstallDebugInfoRequest.SourceInstallerConfig

//TODO move to Xtext
class DebugInfoInstaller {
	static val logger = LoggerFactory.getLogger(DebugInfoInstaller)
	
	@Inject Provider<TraceAsPrimarySourceInstaller> traceAsPrimarySourceInstallerProvider
	@Inject Provider<TraceAsSmapInstaller> traceAsSmapInstaller
	@Inject TraceFileNameProvider traceFileNameProvider
	@Inject TraceRegionSerializer traceRegionSerializer

	def void installDebugInfo(InstallDebugInfoRequest request) {
		for (javaFile : request.generatedJavaFiles) {
			val traceFile = new File(traceFileNameProvider.getTraceFromJava(javaFile.absolutePath))
			installDebugInfo(request, javaFile, traceFile)
		}
	}

	def private void installDebugInfo(InstallDebugInfoRequest request, File javaFile, File traceFile) throws IOException {
		if(!traceFile.exists) 
			return;
		val trace = readTraceFile(traceFile)
		val installer = createTraceToBytecodeInstaller(request,	trace.associatedSrcRelativePath)
		if(installer === null) 
			return;
		val javaFileUri = URI.createFileURI(javaFile.absolutePath)
		val resourceSet = request.resourceSet
		val javaResource = resourceSet.getResource(javaFileUri, true)
		for (type : javaResource.contents.filter(JvmGenericType)) {
			installDebugInfo(request, javaFile, type, trace)
		}
	}

	def private void installDebugInfo(InstallDebugInfoRequest request, File javaFile, JvmGenericType type, AbstractTraceRegion trace) throws IOException {
		val relativePath = '''«type.qualifiedName.replace(".", File.separator)».class'''
		val classesDir = request.classesDir
		val classFile = new File(classesDir, relativePath)
		if (classFile.exists) {
			installDebugInfo(request, javaFile, classFile, trace)
			for (member : type.members.filter(JvmGenericType)) {
				installDebugInfo(request, javaFile, member, trace)
			}
		}
	}

	def private void installDebugInfo(InstallDebugInfoRequest request, File javaFile, File classFile, AbstractTraceRegion trace) throws IOException {
		val traceToBytecodeInstaller = createTraceToBytecodeInstaller(request, trace.associatedSrcRelativePath)
		traceToBytecodeInstaller.setTrace(javaFile.name, trace)
		val outputFile = classFile
		logger.info('''Installing Xtext debug information into «classFile» using «traceToBytecodeInstaller.class.simpleName»''')
		outputFile.parentFile.mkdirs
		val classContent = Files.toByteArray(classFile)
		val newClassContent = traceToBytecodeInstaller.installTrace(classContent) ?: classContent
		Files.write(newClassContent, outputFile)
	}

	def private createTraceToBytecodeInstaller(InstallDebugInfoRequest request, SourceRelativeURI sourceFile) {
		var SourceInstallerConfig debugInfoConfig = request.sourceInstallerByFileExtension.get(sourceFile.URI.fileExtension)

		switch (debugInfoConfig.sourceInstaller) {
			case PRIMARY: {
				val installer = traceAsPrimarySourceInstallerProvider.get
				installer.setHideSyntheticVariables(debugInfoConfig.isHideSyntheticVariables)
				return installer
			}
			case SMAP: {
				return traceAsSmapInstaller.get
			}
			default: {
				return null
			}
		}
	}

	def private AbstractTraceRegion readTraceFile(File traceFile) throws IOException {
		val in = new FileInputStream(traceFile)
		try {
			return traceRegionSerializer.readTraceRegionFrom(in)
		} finally {
			in.close()
		}
	}
}
