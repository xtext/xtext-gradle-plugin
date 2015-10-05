package org.xtext.gradle.test

import org.junit.Test

class BuildingASimpleXtendProject extends AbstractXtendIntegrationTest {

	@Test
	def theGeneratorShouldRunOnValidInput() {
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("build")

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist
	}

	@Test
	def theGeneratorShouldNotRunWhenAllFilesAreUpToDate() {
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("build")
		val secondResult = build("build")
		secondResult.xtextTask.shouldBeUpToDate
	}

	@Test
	def theGeneratorShouldOnlyRunForAffectedFiles() {
		val upStream = createFile('src/main/java/UpStream.xtend', '''
			class UpStream {}
		''')
		val downStream = createFile('src/main/java/DownStream.xtend', '''
			class DownStream {
				UpStream upStream
			}
		''')
		val unrelated = createFile('src/main/java/Unrelated.xtend', '''
			class Unrelated {}
		''')

		build("build")

		upStream.content = '''
			class UpStream {
				def void foo() {}
			}
		'''
		val secondResult = build("build", "-i")

		secondResult.hasRunGeneratorFor(upStream)
		secondResult.hasRunGeneratorFor(downStream)
		secondResult.hasNotRunGeneratorFor(unrelated)
	}
	
	@Test
	def affectedResourcesAreDetectedAcrossXtendAndJava() {
		val upStream = createFile('src/main/java/A.xtend', '''
			class A {}
		''')
		createFile('src/main/java/B.java', '''
			public class B extends A {
			}
		''')
		val downStream = createFile('src/main/java/C.xtend', '''
			class C extends B {}
		''')

		build("build")

		upStream.content = '''
			class A {
				def void foo() {}
			}
		'''
		val secondResult = build("build", "-i")

		secondResult.hasRunGeneratorFor(upStream)
		secondResult.hasRunGeneratorFor(downStream)
	}
	
	@Test
	def void builtInActiveAnnotationsWork() {
		file('src/main/java/HelloWorld.xtend').content = '''
			import org.eclipse.xtend.lib.annotations.Data
			
			@Data 
			class HelloWorld {
				String greeting
				def test() {
					getGreeting
				}
			}
		'''

		build("generateXtext")
	}
	
	@Test
	def void shouldCompileAfterErrorIsFixed() {
		// given
		val file = createFile('src/main/java/HelloWorld.xtend', '''
			class HelloWorld {
				
				def void helloWorld() {
					println "This is Groovy syntax"
				}
				
			}
		''')
		buildAndFail('build')
		
		// expect: no failure
		file.content = '''
			class HelloWorld {
				
				def void helloWorld() {
					println("This is Xtend syntax")
				}
				
			}
		'''
		build('build')
	}
	
	@Test
	def void classFilesAreGenerated() {
		// given
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		// when
		build('build')

		// then
		file('build/classes/main/HelloWorld.class').shouldExist
	}
	
	@Test
	def void classFilesAdhereToPackageStructure() {
		// given
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''

		// when
		build('build')

		// then
		file('build/classes/main/com/example/HelloWorld.class').shouldExist
	}

}

