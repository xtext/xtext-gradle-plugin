package org.xtext.gradle;

import java.io.IOException;
import java.io.InputStream;
import java.util.jar.Manifest;

public class XtextBuilderPluginVersion {
	
	public static final String PLUGIN_VERSION;
	
	static {
		String implementationVersion = XtextBuilderPluginVersion.class.getPackage().getImplementationVersion();
		if (implementationVersion != null) {
			PLUGIN_VERSION = implementationVersion;
		} else {
			String version = null;
			try (InputStream stream = XtextBuilderPluginVersion.class.getResourceAsStream("/META-INF/MANIFEST.MF")) {
				if (stream != null) {
					Manifest mf = new Manifest(stream);
					version = mf.getMainAttributes().getValue("Implementation-Version");
				}
			} catch (IOException e) {
			}
			PLUGIN_VERSION = version;
			
		}
	}

}
