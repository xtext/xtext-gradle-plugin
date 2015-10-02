package org.xtext.gradle.test

import java.io.File
import org.gradle.testkit.runner.BuildResult
import org.gradle.testkit.runner.BuildTask
import org.junit.Before
import org.junit.Rule
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest

class AbstractIntegrationTest {

	@Rule public extension GradleBuildTester tester = new GradleBuildTester
	protected extension ProjectUnderTest rootProject
	protected val extension XtextBuilderAssertions = new XtextBuilderAssertions

	@Before
	def void setup() {
		rootProject = tester.rootProject
		buildFile = '''
			buildscript {
				«repositories»
				dependencies {
					classpath 'org.xtext:xtext-gradle-plugin:«System.getProperty("gradle.project.version") ?: 'unspecified'»'
				}
			}
			
			allprojects {
				«repositories»
			}
		'''
	}
	
	protected def CharSequence getRepositories() '''
		repositories {
			mavenLocal()
			maven {
				url 'https://oss.sonatype.org/content/repositories/snapshots'
			}
			jcenter()
		}
	'''
	
	protected def CharSequence getXtendPluginSnippet() '''
		apply plugin: 'org.xtext.xtend'
		
		dependencies {
			compile 'org.eclipse.xtend:org.eclipse.xtend.lib:2.9.0-SNAPSHOT'
		}
	'''
	
	protected def File createXtendHelloWorld() {
		createFile('src/main/java/HelloWorld.xtend', '''
			class HelloWorld {
				
				def void helloWorld() {
					#['hello', 'world'].forEach[println(toFirstUpper)]
				}
				
			}
		''')
	}
	
	def BuildTask getXtextTask(BuildResult buildResult) {
		buildResult.getXtextTask(rootProject)
	}
	
	def BuildTask getXtextTask(BuildResult buildResult, ProjectUnderTest project) {
		val taskName = '''«project.path»:generateXtext'''
		return buildResult.task(taskName)
	}

}