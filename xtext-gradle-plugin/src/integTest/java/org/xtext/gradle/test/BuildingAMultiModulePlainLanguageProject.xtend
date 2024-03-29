package org.xtext.gradle.test

import org.junit.Test
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest

import static org.junit.Assert.*

//TODO use a different language than Xtend
class BuildingAMultiModulePlainLanguageProject extends AbstractIntegrationTest {

	ProjectUnderTest upStreamProject
	ProjectUnderTest downStreamProject

	override setup() {
		super.setup
		buildFile << '''
			subprojects {
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
							srcDir 'src/main/java'
						}
					}
				}

				generateXtext.classpath .from(configurations.compile)

				task jar(type:Jar) {
					from(xtext.sourceSets.main.files)
				}

				artifacts {
					'default' jar
				}
			}
		'''
		upStreamProject = createSubProject("upStream")
		downStreamProject = createSubProject("downStream")
		buildFile << '''
			project('«downStreamProject.path»').dependencies {
				compile project('«upStreamProject.path»')
			}
		'''
	}

	@Test
	def void upStreamModelsCanBeReferenced() {
		upStreamProject.createFile("src/main/java/A.xtend", '''class A {}''')
		downStreamProject.createFile("src/main/java/B.xtend", '''class B extends A {}''')
		build("generateXtext")
	}

	@Test
	def void generatorOnlyRunsForLocalModels() {
		upStreamProject.createFile("src/main/java/A.xtend", '''class A {}''')
		downStreamProject.createFile("src/main/java/B.xtend", '''class B extends A {}''')
		build("generateXtext")
		val outputs = downStreamProject.file("build/xtend/main").listFiles
		assertTrue(!outputs.exists[name.equals("A.java")])
	}

	@Test
	def void upStreamChangesArePickedUpDownStream() {
		val upStream = upStreamProject.createFile("src/main/java/A.xtend", '''class A {}''')
		downStreamProject.createFile("src/main/java/B.xtend", '''class B extends A {}''')
		build("generateXtext")
		val snapshot = snapshot(downStreamProject.projectDir)

		upStream.content = '''
			class A implements Cloneable {}
		'''
		build("generateXtext", "-i")
		snapshot.assertChangedClasses("B")
	}
}