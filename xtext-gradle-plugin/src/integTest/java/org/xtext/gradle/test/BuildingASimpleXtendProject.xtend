package org.xtext.gradle.test

import org.junit.Ignore
import org.junit.Test

class BuildingASimpleXtendProject extends AbstractXtendIntegrationTest {

    @Test
	def theGeneratorShouldRunAndCompileWhenInvokedInSeperateBuilds() {
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("generateXtext")
		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist

		build("compileJava")

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist
	}

	@Test
	def theGeneratorShouldRunAndCompileWhenInvokedInSeperateBuildsWithJavaPackage() {
		file('src/main/java/org/xtext/it/HelloWorld.xtend').content = '''
			package org.xtext.it
			class HelloWorld {}
		'''

		build("generateXtext")
		file('build/xtend/main/org/xtext/it/HelloWorld.java').shouldExist
		file('build/xtend/main/org/xtext/it/.HelloWorld.java._trace').shouldExist

		build("compileJava")

		file('build/xtend/main/org/xtext/it/HelloWorld.java').shouldExist
		file('build/xtend/main/org/xtext/it/.HelloWorld.java._trace').shouldExist
	}
	
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
		file('build/classes/java/main/HelloWorld.class').shouldExist
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
		file('build/classes/java/main/com/example/HelloWorld.class').shouldExist
	}
	
	@Test
	def void theOutputFolderCanBeConfigured() {
		buildFile << '''
			sourceSets.main.xtendOutputDir = "build/xtend-gen"
		'''
		// given
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''

		// when
		build('build')

		// then
		file('build/xtend-gen/com/example/HelloWorld.java').shouldExist
		file('build/classes/java/main/com/example/HelloWorld.class').shouldExist
	}
	
    @Test
	def void theOutputIsCleanedOnAFullBuild() {
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''
		val staleFile = file('build/xtend/main/com/example/Foo.java')
		staleFile.content = '''
			package com.example;
			public class Foo {}
		'''

		// when
		build('build')

		// then
		staleFile.shouldNotExist
	}
	
	@Test
	def void theOutputIsCleanedWhenCallingGradleClean() {
		val staleFile = file('build/xtend/main/com/example/Foo.java')
		staleFile.content = '''
			package com.example;
			public class Foo {}
		'''

		// when
		build('cleanGenerateXtext')

		// then
		staleFile.shouldNotExist
	}
	
	@Ignore("Doesn't work if we want to keep @SkipWhenEmpty on the XtextGenerate sources")
	@Test
	def void theOutputIsCleanedWhenTheLastXtendFileIsRemoved() {
		val staleFile = file('build/xtend/main/com/example/Foo.java')
		staleFile.content = '''
			package com.example;
			public class Foo {}
		'''

		// when
		build('cleanGenerateXtext')

		// then
		staleFile.shouldNotExist
	}
	
 	@Test
	def void theIndexerCanHandleNonExistentClasspathEntries() {
		file('src/test/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''

		build("build")
	}

 	@Test
	def void theIndexerCanHandleDirectoryClasspathEntries() {
		file('src/main/java/com/example/Foo.xtend').content = '''
			package com.example
			class Foo {}
		'''
		file('src/test/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''

		build("build")
	}

}

