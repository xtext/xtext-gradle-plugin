package org.xtext.gradle.test

import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest
import org.gradle.testkit.runner.TaskOutcome
import static org.junit.Assert.*

//TODO use a different language than Xtend
class BuildingAPlainLanguageProject {
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
		assertEquals(TaskOutcome.UP_TO_DATE, secondResult.task(":generateXtext").outcome)
	}

	@Test
	def theGeneratorShouldOnlyRunForAffectedFiles() {
		val upStream = createFile('src/main/xtend/UpStream.xtend', '''
			class UpStream {}
		''')
		val downStream = createFile('src/main/xtend/DownStream.xtend', '''
			class DownStream {
				UpStream upStream
			}
		''')
		val unrelated = createFile('src/main/xtend/Unrelated.xtend', '''
			class Unrelated {}
		''')

		build("generateXtext")
		upStream.content = '''
			class UpStream {
				def void foo() {}
			}
		'''
		val secondResult = build("generateXtext", "-i")
		
		secondResult.hasRunGeneratorFor(upStream)
		secondResult.hasRunGeneratorFor(downStream)
		secondResult.hasNotRunGeneratorFor(unrelated)
	}
}