package org.xtext.gradle.test

import org.junit.Test
import org.junit.Rule
import org.junit.Before
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest

class BuildingAMultiModuleXtendProject {
	@Rule public extension GradleBuildTester tester = new GradleBuildTester
	
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
		executeTasks("build").shouldSucceed
	}
	
	
	@Test
	def void downStreamProjectsAreNotRebuiltWhenUpStreamClassesStayTheSame() {
		val upStreamFile = upStreamProject.createFile("src/main/java/A.xtend", '''class A {}''')
		downStreamProject.createFile("src/main/java/B.xtend", '''class B extends A {}''')
		executeTasks("build")
		val snapshot = downStreamProject.snapshotBuildDir
		
		upStreamFile.content = '''
			class A 
			{}
		'''
		executeTasks("build")
		val diff = snapshot.changesSince(downStreamProject.snapshotBuildDir)
		
		diff.shouldBeEmpty
	}
	
	@Test
	def void upStreamChangesArePickedUpDownStream() {
		val upStreamFile = upStreamProject.createFile("src/main/java/A.xtend", '''class A {}''')
		downStreamProject.createFile("src/main/java/B.xtend", '''class B extends A {}''')
		executeTasks("build")
		val snapshot = downStreamProject.snapshotBuildDir
		val downStreamJavaFile = downStreamProject.file("build/xtend/main/B.java")
		
		upStreamFile.content = '''
			class A implements Cloneable {}
		'''
		executeTasks("build")
		val diff = snapshot.changesSince(downStreamProject.snapshotBuildDir)
		diff.shouldBeUnchanged(downStreamJavaFile)
		//TODO use testkit api to assert not UP-TO-DATE
	}
}