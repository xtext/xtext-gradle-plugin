package org.xtext.gradle.test

import org.junit.Test
import org.junit.Rule
import org.junit.Before
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest
import org.gradle.testkit.runner.TaskOutcome
import static org.junit.Assert.*

class BuildingAMultiModuleXtendProject {
	@Rule public extension GradleBuildTester tester = new GradleBuildTester
	val extension XtextBuilderAssertions = new XtextBuilderAssertions
	ProjectUnderTest upStreamProject
	ProjectUnderTest downStreamProject
	
	@Before
	def void setup() {
		upStreamProject = rootProject.createSubProject("upStream")
		downStreamProject = rootProject.createSubProject("downStream")
		rootProject.buildFile = '''
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
			
			subprojects {
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
		assertEquals(TaskOutcome.UP_TO_DATE, secondResult.task(":downStream:generateXtext").outcome)
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