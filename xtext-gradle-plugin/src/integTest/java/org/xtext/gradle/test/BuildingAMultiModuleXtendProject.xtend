package org.xtext.gradle.test

import org.junit.Test
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest

class BuildingAMultiModuleXtendProject extends AbstractIntegrationTest {
	
	ProjectUnderTest upStreamProject
	ProjectUnderTest downStreamProject
	
	override setup() {
		super.setup
		upStreamProject = rootProject.createSubProject("upStream")
		downStreamProject = rootProject.createSubProject("downStream")
		rootProject.buildFile << '''
			subprojects {
				«xtendPluginSnippet»
			}
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

}