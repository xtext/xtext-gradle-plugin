package org.xtext.builder.standalone;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.workspace.ISourceFolder;

public class GradleSourceFolder implements ISourceFolder {

	private GradleProjectConfig parent;
	private URI path;

	public GradleSourceFolder(GradleProjectConfig parent, URI path) {
		this.parent = parent;
		this.path = path;
	}

	@Override
	public String getName() {
		return getPath().deresolve(parent.getPath()).trimSegments(1).path();
	}

	@Override
	public URI getPath() {
		return path;
	}

}
