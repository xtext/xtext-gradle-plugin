package org.xtext.gradle.test

import org.junit.Test

class BuildingAgainstDifferentXtextVersions extends AbstractIntegrationTest {

	@Test def theGeneratorShouldRunOn_Xtext_2_9_0() { assertBuildWithXtext("2.9.0") }

	@Test def theGeneratorShouldRunOn_Xtext_2_9_1() { assertBuildWithXtext("2.9.1") }

	@Test def theGeneratorShouldRunOn_Xtext_2_9_2() { assertBuildWithXtext("2.9.2") }

	@Test def theGeneratorShouldRunOn_Xtext_2_10_0() { assertBuildWithXtext("2.10.0") }

	@Test def theGeneratorShouldRunOn_Xtext_2_11_0() { assertBuildWithXtext("2.11.0") }

	@Test def theGeneratorShouldRunOn_Xtext_2_12_0() { assertBuildWithXtext("2.12.0") }

	@Test def theGeneratorShouldRunOn_Xtext_2_13_0() { assertBuildWithXtext("2.13.0") }

	@Test def theGeneratorShouldRunOn_Xtext_2_14_0() { assertBuildWithXtext("2.14.0") }

	private def assertBuildWithXtext(String xtextVersion) {
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

		file('src/main/xtend/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("generateXtext")

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist
	}

}
