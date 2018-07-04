package org.xtext.gradle.test

import org.junit.Test
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest

class BuildingAMultiModuleXtendProject extends AbstractXtendIntegrationTest {
	
	ProjectUnderTest upStreamProject
	ProjectUnderTest downStreamProject
	
	override protected applyXtendPlugin() {
		rootProject.buildFile << '''
			subprojects {
				«xtendPluginSnippet»
			}
		'''
	}
	
	override setup() {
		super.setup
		upStreamProject = rootProject.createSubProject("upStream")
		downStreamProject = rootProject.createSubProject("downStream")
		rootProject.buildFile << '''
			project('«downStreamProject.path»').dependencies {
				compile project('«upStreamProject.path»')
			}
		'''
	}
	
	@Test
	def void upStreamClassesCanBeReferenced() {
		upStreamProject.createFile("src/main/java/A.xtend", '''class A {}''')
		downStreamProject.createFile("src/main/java/B.xtend", '''class B extends A {}''')
		build("build")
	}
	
	
	@Test
	def void downStreamProjectsAreNotRebuiltWhenUpStreamClassesStayTheSame() {
		val upStreamFile = upStreamProject.createFile("src/main/java/A.xtend", '''class A {}''')
		downStreamProject.createFile("src/main/java/B.xtend", '''class B extends A {}''')
		build("build")
		
		upStreamFile.content = '''
			class A 
			{}
		'''
		val secondResult = build("build")
		secondResult.getXtextTask(downStreamProject).shouldBeUpToDate
	}
	
	@Test
	def void upStreamChangesArePickedUpDownStream() {
		val upStream = upStreamProject.createFile("src/main/java/A.xtend", '''class A {}''')
		val downStream = downStreamProject.createFile("src/main/java/B.xtend", '''class B extends A {}''')
		build("build")
		
		upStream.content = '''
			class A implements Cloneable {}
		'''
		val result = build("build", "-i")
		result.hasRunGeneratorFor(downStream)
	}

	@Test
	def void activeAnnotationsCanGenerateFilesUsingOutputConfigurations() {
		upStreamProject.createFile('src/main/java/com/example/Generate.xtend', '''
			package com.example
			import java.util.List
			import org.eclipse.xtend.lib.macro.AbstractClassProcessor
			import org.eclipse.xtend.lib.macro.CodeGenerationContext
			import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
			class GenerateProcessor extends AbstractClassProcessor {
				override doGenerateCode(List<? extends ClassDeclaration> annotatedSourceElements, extension CodeGenerationContext context) {
				    for (clazz : annotatedSourceElements) {
				      val filePath = clazz.compilationUnit.filePath
				      val folder = context.getTargetFolder(filePath)
				      val file = folder.append("Test.info")
				      file.contents = clazz.getSimpleName
				    }
				  }
			}
		''')
		upStreamProject.createFile('src/main/java/com/example/GenerateProcessor.xtend', '''
			package com.example
			import org.eclipse.xtend.lib.macro.Active
			@Active(GenerateProcessor)
			annotation Generate {}
		''')
		downStreamProject.createFile('src/main/java/com/example/HelloWorld.xtend', '''
			package com.example
			@Generate
			class HelloWorld {}
		''')

		build('build')

		file('downStream/build/xtend/main/Test.info').shouldExist
	}

}