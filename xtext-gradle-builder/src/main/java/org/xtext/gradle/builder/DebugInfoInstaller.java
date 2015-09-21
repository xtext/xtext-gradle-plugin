package org.xtext.gradle.builder;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.xtext.common.types.JvmGenericType;
import org.eclipse.xtext.common.types.JvmMember;
import org.eclipse.xtext.generator.trace.AbstractTraceRegion;
import org.eclipse.xtext.generator.trace.ITraceToBytecodeInstaller;
import org.eclipse.xtext.generator.trace.SourceRelativeURI;
import org.eclipse.xtext.generator.trace.TraceAsPrimarySourceInstaller;
import org.eclipse.xtext.generator.trace.TraceAsSmapInstaller;
import org.eclipse.xtext.generator.trace.TraceFileNameProvider;
import org.eclipse.xtext.generator.trace.TraceRegionSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.xtext.gradle.builder.InstallDebugInfoRequest.SourceInstallerConfig;

import com.google.common.base.Throwables;
import com.google.common.io.Files;
import com.google.inject.Inject;
import com.google.inject.Provider;

//TODO move to Xtext
public class DebugInfoInstaller {
	
	private static final Logger logger = LoggerFactory.getLogger(DebugInfoInstaller.class);

	@Inject
	private Provider<TraceAsPrimarySourceInstaller> traceAsPrimarySourceInstallerProvider;

	@Inject
	private Provider<TraceAsSmapInstaller> traceAsSmapInstaller;

	@Inject
	private TraceFileNameProvider traceFileNameProvider;

	@Inject
	private TraceRegionSerializer traceRegionSerializer;

	public void installDebugInfo(InstallDebugInfoRequest request) {
		for (File javaFile : request.getGeneratedJavaFiles()) {
			File traceFile = new File(traceFileNameProvider.getTraceFromJava(javaFile.getAbsolutePath()));
			try {
				installDebugInfo(request, javaFile, traceFile);
			} catch (IOException e) {
				throw Throwables.propagate(e);
			}
		}
	}

	private void installDebugInfo(InstallDebugInfoRequest request, File javaFile, File traceFile) throws IOException {
		if (!traceFile.exists())
			return;
		AbstractTraceRegion trace = readTraceFile(traceFile);
		ITraceToBytecodeInstaller installer = createTraceToBytecodeInstaller(request, trace.getAssociatedSrcRelativePath());
		if (installer == null)
			return;
		URI javaFileUri = URI.createFileURI(javaFile.getAbsolutePath());
		ResourceSet resourceSet = request.getResourceSet();
		Resource javaResource = resourceSet.getResource(javaFileUri, true);
		javaResource.getContents();
		for (EObject object : javaResource.getContents()) {
			if (object instanceof JvmGenericType) {
				JvmGenericType type = (JvmGenericType) object;
				installDebugInfo(request, javaFile, type, trace);
			}
		}
		resourceSet.getResources().clear();
	}
	
	private void installDebugInfo(InstallDebugInfoRequest request, File javaFile, JvmGenericType type, AbstractTraceRegion trace) throws IOException {
		String relativePath = type.getQualifiedName().replace(".", File.separator) + ".class";
		File classFile = new File (request.getClassesDir(), relativePath);
		installDebugInfo(request, javaFile, classFile, trace);
		for (JvmMember member : type.getMembers()) {
			if (member instanceof JvmGenericType) {
				installDebugInfo(request, javaFile, (JvmGenericType) member, trace);
			}
		}
	}

	private void installDebugInfo(InstallDebugInfoRequest request, File javaFile, File classFile, AbstractTraceRegion trace) throws IOException {
		ITraceToBytecodeInstaller traceToBytecodeInstaller = createTraceToBytecodeInstaller(request, trace.getAssociatedSrcRelativePath());
		traceToBytecodeInstaller.setTrace(javaFile.getName(), trace);
		File outputFile = new File(classFile.getAbsolutePath().replace(request.getClassesDir().getAbsolutePath(), request.getOutputDir().getAbsolutePath()));
		logger.info("Installing Xtext debug information into " + classFile + " using " + traceToBytecodeInstaller.getClass().getSimpleName());
		outputFile.getParentFile().mkdirs();
		Files.write(traceToBytecodeInstaller.installTrace(Files.toByteArray(classFile)), outputFile);
	}

	private ITraceToBytecodeInstaller createTraceToBytecodeInstaller(InstallDebugInfoRequest request, SourceRelativeURI sourceFile) {
		SourceInstallerConfig debugInfoConfig = request.getSourceInstallerByFileExtension().get(sourceFile.getURI().fileExtension());
		switch(debugInfoConfig.getSourceInstaller()) {
		case PRIMARY:
			TraceAsPrimarySourceInstaller installer = traceAsPrimarySourceInstallerProvider.get();
			installer.setHideSyntheticVariables(debugInfoConfig.isHideSyntheticVariables());
			return installer;
		case SMAP:
			return traceAsSmapInstaller.get();
		case NONE:
		default:
			return null;
		}
	}

	private AbstractTraceRegion readTraceFile(File traceFile) throws IOException {
		InputStream in = new FileInputStream(traceFile);
		try {
			return traceRegionSerializer.readTraceRegionFrom(in);
		}finally{
			in.close();
		}
	}
}
