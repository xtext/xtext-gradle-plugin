package org.xtext.gradle.builder;

import java.io.File;
import java.util.Collection;
import java.util.Set;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.util.UriUtil;
import org.eclipse.xtext.workspace.IProjectConfig;
import org.eclipse.xtext.workspace.ISourceFolder;
import org.xtext.gradle.protocol.GradleBuildRequest;

import com.google.common.base.Predicate;
import com.google.common.collect.Iterables;
import com.google.common.collect.Sets;

public class GradleProjectConfig implements IProjectConfig {
	
	private GradleBuildRequest request;

	public GradleProjectConfig(GradleBuildRequest request) {
		this.request = request;
	}
	
	@Override
	public String getName() {
		return request.getProjectName();
	}
	
	@Override
	public URI getPath() {
		return UriUtil.createFolderURI(request.getProjectDir());
	}
	
	@Override
	public Set<? extends ISourceFolder> getSourceFolders() {
		Collection<File> folders = request.getSourceFolders();
		Set<ISourceFolder> sourceFolders = Sets.newHashSet();
		for (File folder : folders) {
			URI uri = UriUtil.createFolderURI(folder);
			sourceFolders.add(new GradleSourceFolder(this, uri));
		}
		return sourceFolders;
	}
	
	@Override
	public ISourceFolder findSourceFolderContaining(final URI member) {
		Predicate<? super ISourceFolder> containingMember = new Predicate<ISourceFolder>() {
			@Override
			public boolean apply(ISourceFolder folder) {
				return UriUtil.isPrefixOf(folder.getPath(), member);
			}
			
		};
		return Iterables.find(getSourceFolders(), containingMember, null);
	}
	
}