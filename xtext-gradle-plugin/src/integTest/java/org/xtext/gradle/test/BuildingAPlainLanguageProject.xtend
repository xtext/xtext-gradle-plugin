package org.xtext.gradle.test

import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest

//TODO use a different language than Xtend
class BuildingAPlainLanguageProject {
	@Rule public extension GradleBuildTester tester = new GradleBuildTester
	extension ProjectUnderTest rootProject

	@Before
	def void setup() {
		rootProject = tester.rootProject
		buildFile = '''
			buildscript {
				repositories {
					mavenLocal()
					maven {
						url 'https://oss.sonatype.org/content/repositories/snapshots'
					}
					jcenter()
				}
				dependencies {
					classpath 'org.xtext:xtext-gradle-plugin:«System.getProperty("gradle.project.version") ?: 'unspecified'»'
				}
			}
			
			apply plugin: 'org.xtext.builder'
			
			repositories {
				mavenLocal()
				maven {
					url 'https://oss.sonatype.org/content/repositories/snapshots'
				}
				jcenter()
			}
			
			configurations {
				compile
			}
			
			dependencies {
				compile 'org.eclipse.xtend:org.eclipse.xtend.lib:2.9.0-SNAPSHOT'
				xtextTooling 'org.eclipse.xtend:org.eclipse.xtend.core:2.9.0-SNAPSHOT'
			}
			
			xtext {
				version = '2.9.0-SNAPSHOT'
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

		executeTasks("generateXtext").shouldSucceed

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist
	}

	@Test
	def theGeneratorShouldNotRunWhenAllFilesAreUpToDate() {
		file('src/main/xtend/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		executeTasks("generateXtext")
		val javaFile = file("build/xtend/main/HelloWorld.java")
		val before = snapshotBuildDir

		executeTasks("generateXtext")
		val after = snapshotBuildDir
		val diff = after.changesSince(before)
		
		diff.shouldBeUntouched(javaFile)
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

		executeTasks("generateXtext")

		val upStreamJava = file("build/xtend/main/UpStream.java")
		val downStreamJava = file("build/xtend/main/DownStream.java")
		val unrelatedJava = file("build/xtend/main/Unrelated.java")
		val before = snapshotBuildDir

		upStream.content = '''
			class UpStream {
				def void foo() {}
			}
		'''
		executeTasks("generateXtext")
		val after = snapshotBuildDir
		val diff = after.changesSince(before)

		diff.shouldBeModified(upStreamJava)
		diff.shouldBeUnchanged(downStreamJava)
		diff.shouldBeTouched(downStreamJava)
		diff.shouldBeUntouched(unrelatedJava)
	}
}