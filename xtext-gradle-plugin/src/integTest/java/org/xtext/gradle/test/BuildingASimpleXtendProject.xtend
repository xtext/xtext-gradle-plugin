package org.xtext.gradle.test

import java.util.zip.ZipFile
import org.apache.maven.artifact.versioning.ComparableVersion
import org.junit.Test

import static org.junit.Assert.*
import static org.junit.Assume.*

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
		createFile('src/main/java/DownStream.xtend', '''
			class DownStream {
				UpStream upStream
			}
		''')
		createFile('src/main/java/Unrelated.xtend', '''
			class Unrelated {}
		''')

		build("build")
		val snapshot = snapshot(projectDir)

		upStream.content = '''
			class UpStream {
				def void foo() {}
			}
		'''
		build("build")

		snapshot.assertChangedClasses("UpStream", "DownStream")
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
		createFile('src/main/java/C.xtend', '''
			class C extends B {}
		''')

		build("build")
		val snapshot = snapshot(projectDir)

		upStream.content = '''
			class A {
				def void foo() {}
			}
		'''
		build("build")

		snapshot.assertChangedClasses("A", "C")
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

	@Test
	def void defaultMethodsAreInherited() {
		assumeTrue(xtextVersion >= new ComparableVersion("2.11"))
		file('src/main/java/I.java').content = '''
			interface I {
				default void foo() {
				}
			}
		'''
		file('src/main/java/A.xtend').content = '''
			class A implements I {
			}
		'''

		build("generateXtext")
	}

	@Test
	def void sourcesAreIncludedInTheSourceJar() {
		file('src/main/java/HelloWorld.xtend') << '''
			class HelloWorld {}
		'''
		buildFile << '''
			task sourceJar(type: Jar) {
				archiveClassifier = 'sources'
				from(sourceSets.main.allSource)
			}
		'''
		build("sourceJar")
		val sourceJar = new ZipFile(file('build/libs/root-sources.jar'))
		try {
			assertNotNull(sourceJar.getEntry('HelloWorld.xtend'))
			assertNotNull(sourceJar.getEntry('HelloWorld.java'))
		} finally {
			sourceJar.close
		}
	}

	@Test
	def void debugInfoCanBeInstalledInSeparateGradleInvocations() {
		file('src/main/java/org/xtext/it/HelloWorld.xtend').content = '''
			package org.xtext.it
			class HelloWorld {}
		'''

		build("generateXtext")
		build("compileJava")
	}

	@Test
	def void theGeneratorRunsBeforeCompilingJava() {
		file('src/main/java/A.java').content = '''
			interface A extends B {
			}
		'''
		file('src/main/java/B.xtend').content = '''
			interface B {
			}
		'''

		build("compileJava")
	}

}

