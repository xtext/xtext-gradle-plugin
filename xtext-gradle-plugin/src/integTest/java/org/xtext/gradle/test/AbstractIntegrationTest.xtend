package org.xtext.gradle.test

import java.io.File
import org.gradle.testkit.runner.BuildResult
import org.gradle.testkit.runner.BuildTask
import org.junit.Before
import org.junit.Rule
import org.xtext.gradle.test.GradleBuildTester.ProjectUnderTest

abstract class AbstractIntegrationTest {

	@Rule public extension GradleBuildTester tester = new GradleBuildTester
	protected extension ProjectUnderTest rootProject

	final static String XTEXT_VERSION = System.getProperty("xtext.version", "2.9.0")

	@Before
	def void setup() {
		rootProject = tester.rootProject
		buildFile = '''
			plugins {
				id 'org.xtext.builder' apply false
			}
			allprojects {
				«repositories»
			}
		'''
		createFile('gradle.properties', 'org.gradle.jvmargs=-XX:MaxMetaspaceSize=512m')
	}

	protected def CharSequence getRepositories() '''
		repositories {
			mavenCentral()
		}
	'''

	def BuildTask getXtextTask(BuildResult buildResult) {
		buildResult.getXtextTask(rootProject)
	}

	def BuildTask getXtextTask(BuildResult buildResult, ProjectUnderTest project) {
		val taskName = '''«project.path»:generateXtext'''
		return buildResult.task(taskName)
	}

	def OutputSnapshot snapshot(File baseDir) {
		new OutputSnapshot(baseDir)
	}

	def String getXtextVersion() {
		XTEXT_VERSION
	}

	def String getGradleVersion() {
		GradleBuildTester.GRADLE_VERSION
	}

	def String getImplementationScope() {
		if (gradleVersion > '5') 'implementation' else 'compile'
	}

}
