package org.xtext.gradle.test

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

}