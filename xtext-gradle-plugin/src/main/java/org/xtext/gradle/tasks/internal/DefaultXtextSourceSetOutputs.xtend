package org.xtext.gradle.tasks.internal

import groovy.lang.Closure
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.internal.AbstractNamedDomainObjectContainer
import org.gradle.internal.reflect.Instantiator
import org.xtext.gradle.tasks.LanguageSourceSetOutputs
import org.xtext.gradle.tasks.SourceInstaller
import org.xtext.gradle.tasks.XtextSourceSetOutputs
import org.xtext.gradle.tasks.LanguageSourceSetOutput

class DefaultXtextSourceSetOutputs extends AbstractNamedDomainObjectContainer<LanguageSourceSetOutputs> implements XtextSourceSetOutputs {
	Project project

	new(Project project, Instantiator instantiator) {
		super(LanguageSourceSetOutputs, instantiator)
		this.project = project
	}
	
	override getDirs() {
		project.files(map[dirs])
	}
	
	override protected doCreate(String name) {
		new DefaultLanguageSourceSetOutputs(project,instantiator, name)
	}
	
	//TODO Xtend bug - these overrides are not necessary
	override <S extends LanguageSourceSetOutputs> withType(Class<S> arg0) {
		super.withType(arg0)
	}
	
	override <S extends LanguageSourceSetOutputs> withType(Class<S> arg0, Action<? super S> arg1) {
		super.withType(arg0, arg1)
	}
	
	override <S extends LanguageSourceSetOutputs> withType(Class<S> arg0, Closure arg1) {
		super.withType(arg0, arg1)
	}
}

class DefaultLanguageSourceSetOutputs extends AbstractNamedDomainObjectContainer<LanguageSourceSetOutput> implements LanguageSourceSetOutputs {
	Project project
	@Accessors val String name
	
	new(Project project, Instantiator instantiator, String name) {
		super(LanguageSourceSetOutput, instantiator)
		this.project = project
		this.name = name
	}
	
	override getDirs() {
		project.files(map[dir])
	}
	
	override protected doCreate(String name) {
		new DefaultLanguageSourceSetOutput(project, name)
	}
	
	//TODO Xtend bug - these overrides are not necessary
	override <S extends LanguageSourceSetOutput> withType(Class<S> arg0) {
		super.withType(arg0)
	}
	
	override <S extends LanguageSourceSetOutput> withType(Class<S> arg0, Action<? super S> arg1) {
		super.withType(arg0, arg1)
	}
	
	override <S extends LanguageSourceSetOutput> withType(Class<S> arg0, Closure arg1) {
		super.withType(arg0, arg1)
	}
}

@FinalFieldsConstructor
class DefaultLanguageSourceSetOutput implements LanguageSourceSetOutput {
	val Project project
	@Accessors val String name
	Object dir
	@Accessors boolean hideSyntheticVariables
	@Accessors boolean producesJava
	@Accessors SourceInstaller sourceInstaller
	
	override getDir() {
		project.file(dir)
	}
	
	override setDir(Object dir) {
		this.dir = dir
	}
}