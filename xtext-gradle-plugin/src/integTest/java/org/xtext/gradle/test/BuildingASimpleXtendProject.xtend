package org.xtext.gradle.test

import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest
import static org.junit.Assert.*
import org.gradle.testkit.runner.TaskOutcome
import org.junit.Ignore

class BuildingASimpleXtendProject {
	@Rule public extension GradleBuildTester tester = new GradleBuildTester
	val extension XtextBuilderAssertions = new XtextBuilderAssertions
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
			
			apply plugin: 'org.xtext.xtend'
			
			repositories {
				mavenLocal()
				maven {
					url 'https://oss.sonatype.org/content/repositories/snapshots'
				}
				jcenter()
			}
			
			dependencies {
				compile 'org.eclipse.xtend:org.eclipse.xtend.lib:2.9.0-SNAPSHOT'
			}
			
			xtext {
				version = '2.9.0-SNAPSHOT'
			}
		'''
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
		assertEquals(TaskOutcome.UP_TO_DATE, secondResult.task(":generateXtext").outcome)
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
	@Ignore("Fails due to assumption in xtend.core that URLClassLoaders are used")
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
}

