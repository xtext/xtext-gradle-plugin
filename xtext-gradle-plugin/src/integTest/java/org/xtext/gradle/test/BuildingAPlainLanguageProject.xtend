package org.xtext.gradle.test

import org.gradle.testkit.runner.TaskOutcome
import org.junit.Test

//TODO use a different language than Xtend
class BuildingAPlainLanguageProject extends AbstractIntegrationTest {

	override setup() {
		super.setup
		buildFile << '''
			apply plugin: 'org.xtext.builder'

			configurations {
				compile
			}

			dependencies {
				compile 'org.eclipse.xtend:org.eclipse.xtend.lib:«xtextVersion»'
				xtextLanguages 'org.eclipse.xtend:org.eclipse.xtend.core:«xtextVersion»'
			}

			xtext {
				version = '«xtextVersion»'
				languages {
					xtend {
						setup = 'org.eclipse.xtend.core.XtendStandaloneSetup'
					}
				}
				sourceSets {
					main {
						srcDir 'src/main/xtend'
					}
				}
			}

			generateXtext.classpath = configurations.compile
		'''
	}

	@Test
	def theGeneratorShouldRunOnValidInput() {
		file('src/main/xtend/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("generateXtext")

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist
	}

	@Test
	def theGeneratorShouldNotRunWhenAllFilesAreUpToDate() {
		file('src/main/xtend/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("generateXtext")
		val secondResult = build("generateXtext")
		secondResult.xtextTask.shouldBeUpToDate
	}

	@Test
	def theGeneratorShouldOnlyRunForAffectedFiles() {
		val upStream = createFile('src/main/xtend/UpStream.xtend', '''
			class UpStream {}
		''')
		createFile('src/main/xtend/DownStream.xtend', '''
			class DownStream {
				UpStream upStream
			}
		''')
		createFile('src/main/xtend/Unrelated.xtend', '''
			class Unrelated {}
		''')
		build("generateXtext")
		val snapshot = snapshot(projectDir)

		upStream.content = '''
			class UpStream {
				def void foo() {}
			}
		'''
		build("generateXtext")

		snapshot.assertChangedClasses("UpStream", "DownStream")
	}

	@Test
	def void generateOnceFoldersAreNotCleanedByCleanBuilds() {
		buildFile << '''xtext.languages.xtend.generator.outlet.cleanAutomatically = false'''
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
		build('generateXtext')

		// then
		staleFile.shouldExist
	}

	@Test
	def void generateOnceFilesAreNotOverwrittenWhenTheirSourceChanges() {
		buildFile << '''xtext.languages.xtend.generator.outlet.cleanAutomatically = false'''
		val sourceFile = file('src/main/java/com/example/HelloWorld.xtend')
		sourceFile.content = '''
			package com.example
			class HelloWorld {}
		'''
		build('generateXtext')
		val snapshot = snapshot(projectDir)

		sourceFile << "//change"
		build('generateXtext')
		snapshot.assertChangedClasses()
	}

	@Test
	def void generateOnceFoldersAreNotCleanedByGradleClean() {
		buildFile << '''xtext.languages.xtend.generator.outlet.cleanAutomatically = false'''
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
		build('cleanGenerateXtext')

		// then
		staleFile.shouldExist
	}

	/*
	 * We currently lack a language with multiple file extensions,
	 * so we test that an empty set will be detected as "no sources"
	 * to at least have some coverage for the fact that fileExtensions
	 * is indeed a Set.
	 */
	@Test
	def void canOverrideFileExtensions() {
		buildFile << '''xtext.languages.xtend.fileExtensions = []'''
		file('src/main/java/HelloWorld.xtend').content = '''class HelloWorld {}'''
		build('generateXtext').xtextTask.shouldBe(TaskOutcome.NO_SOURCE)
	}
}