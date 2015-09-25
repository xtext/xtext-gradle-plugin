package org.xtext.gradle.test

import org.junit.Ignore
import org.junit.Test

class WhenSettingsChange extends AbstractIntegrationTest {

	override setup() {
		super.setup
		buildFile << '''
			apply plugin: 'org.xtext.xtend'
			
			dependencies {
				compile 'org.eclipse.xtend:org.eclipse.xtend.lib:2.9.0-SNAPSHOT'
			}
		'''
	}

	@Test @Ignore
	def void shouldRecompileWhenSettingsChange() {
		// given
		createFile('src/main/java/HelloWorld.xtend', '''
			class HelloWorld {
				
				def void helloWorld() {
					#['hello', 'world'].forEach[println(toFirstUpper)]
				}		
				
			}
		''')
		buildFile << '''
			xtext {
				languages {
					xtend {
						generator {
							javaSourceLevel = "1.7"
						}
					}
				}
			}
		'''
		build('build').xtextTask.shouldNotBeUpToDate
		build('build').xtextTask.shouldBeUpToDate
		
		// when
		buildFile.content = buildFile.contentAsString.replace('''javaSourceLevel = "1.7"''', '''javaSourceLevel = "1.8"''')
		val result = build('build')

		// then
		result.xtextTask.shouldNotBeUpToDate
	}

}