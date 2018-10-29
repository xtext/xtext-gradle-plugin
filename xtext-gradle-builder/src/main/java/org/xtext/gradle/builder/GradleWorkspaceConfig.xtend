/*******************************************************************************
 * Copyright (c) 2018 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.xtext.gradle.builder


import org.eclipse.emf.common.util.URI
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.workspace.IProjectConfig
import org.eclipse.xtext.workspace.IWorkspaceConfig
import static extension org.eclipse.xtext.util.UriUtil.*

/**
 * @author dietrich - Initial contribution and API
 */
@Data
class GradleWorkspaceConfig implements IWorkspaceConfig {
	
	IProjectConfig projectConfig
	
	override findProjectByName(String name) {
		if (projectConfig.name == name)
			return projectConfig
	}
	
	override findProjectContaining(URI member) {
		if (projectConfig.path.isPrefixOf(member))
			return projectConfig
	}
	
	override getProjects() {
		return #{projectConfig}
	}
	
}