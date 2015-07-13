package org.xtext.gradle.test

import org.junit.Before
import org.junit.Rule
import org.junit.Test

class BuildingASimpleXtendProject {
	@Rule public extension ProjectUnderTest = new ProjectUnderTest

	@Before
	def void setup() {
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
			
			apply plugin: 'java'
			apply plugin: 'org.xtext.builder'
			apply plugin: 'org.xtext.java'
			
			repositories {
				mavenLocal()
				maven {
					url 'https://oss.sonatype.org/content/repositories/snapshots'
				}
				jcenter()
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
						generator {
							outlet {
								producesJava = true
							}
						}
					}
				}
			}
		'''
	}

	@Test
	def theGeneratorShouldRunOnValidInput() {
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		executeTasks("build").shouldSucceed

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist
	}

	@Test
	def theGeneratorShouldNotRunWhenAllFilesAreUpToDate() {
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		executeTasks("build")
		val javaFile = file("build/xtend/main/HelloWorld.java")
		val before = snapshot

		executeTasks("build")
		val after = snapshot
		val diff = after.changesSince(before)
		
		diff.shouldBeUntouched(javaFile)
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

		executeTasks("build")

		val upStreamJava = file("build/xtend/main/UpStream.java")
		val downStreamJava = file("build/xtend/main/DownStream.java")
		val unrelatedJava = file("build/xtend/main/Unrelated.java")
		val before = snapshot

		upStream.content = '''
			class UpStream {
				def void foo() {}
			}
		'''
		executeTasks("build")
		val after = snapshot
		val diff = after.changesSince(before)

		diff.shouldBeModified(upStreamJava)
		diff.shouldBeUnchanged(downStreamJava)
		diff.shouldBeTouched(downStreamJava)
		diff.shouldBeUntouched(unrelatedJava)
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

		executeTasks("build")

		val aJava = file("build/xtend/main/A.java")
		val cJava = file("build/xtend/main/C.java")
		val before = snapshot

		upStream.content = '''
			class A {
				def void foo() {}
			}
		'''
		executeTasks("build")
		val after = snapshot
		val diff = after.changesSince(before)

		diff.shouldBeModified(aJava)
		diff.shouldBeUnchanged(cJava)
		diff.shouldBeTouched(cJava)
	}
}

