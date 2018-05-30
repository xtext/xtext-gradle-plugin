package org.xtext.gradle.test

import org.junit.Test

class WhenUsingXtextForProductionAndXtendForTests extends AbstractIntegrationTest {

	override setup() {
		super.setup
		buildFile << '''
			apply plugin: 'java'
			apply plugin: 'org.xtext.xtend'
			apply plugin: 'org.xtext.builder'
			
			configurations {
				compile
			}
			
			dependencies {
				compile 'org.eclipse.xtend:org.eclipse.xtend.lib:«XTEXT_VERSION»'
				xtextLanguages 'org.eclipse.xtend:org.eclipse.xtend.core:«XTEXT_VERSION»'
			}
			
			xtext {
				version = '«XTEXT_VERSION»'
				languages {
					xtend {
						setup = 'org.eclipse.xtend.core.XtendStandaloneSetup'
					}
				}
				sourceSets {
					main {
						srcDir 'src/main/xtend'
					}
					test {
						srcDir 'src/test/xtend'
					}
				}
			}
			
			generateXtext.classpath = configurations.compile
		'''
	}

	@Test def buildShouldCreateJavaFilesInOutputFoldersAsDefinedbySourceSets() {
		file('src/main/xtend/HelloWorld.xtend').content = '''
			public class HelloWorld {}
		'''

		file('src/test/xtend/HelloWorldTest.xtend').content = '''
			class HelloWorldTest {
				val HelloWorld = new HelloWorld
			}
		'''

		build("generateXtext", "test")

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/test/HelloWorldTest.java').shouldExist
	}
}
