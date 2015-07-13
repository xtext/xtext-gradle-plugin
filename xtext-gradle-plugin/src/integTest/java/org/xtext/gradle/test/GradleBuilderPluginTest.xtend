package org.xtext.gradle.test

import com.google.common.base.Charsets
import com.google.common.io.Files
import java.io.File
import org.gradle.tooling.GradleConnector
import org.junit.Assert
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class GradleBuilderPluginTest {
	@Rule public TemporaryFolder temp = new TemporaryFolder
	
	@Test
	def shouldRunTheGeneratorOnValidInput() {
		val projectFolder = temp.newFolder("myProject")
		new File(projectFolder, 'build.gradle').content = '''
			buildscript {
				repositories {
					mavenLocal()
					mavenCentral()
				}
				dependencies {
					classpath 'org.xtext:xtext-gradle-plugin:«System.getProperty("gradle.project.version")»'
				}
			}
			
			apply plugin: 'java'
			apply plugin: 'org.xtext.builder'
			apply plugin: 'org.xtext.java'

			repositories {
				mavenLocal()
				mavenCentral()
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
		'''
		
		new File(projectFolder, 'src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {
				def static void main(String... args) {
					println("Hello World!")
				}
			}
		'''
		
		val project = GradleConnector.newConnector
			.forProjectDirectory(projectFolder)
			.connect

		project.newBuild
			.forTasks("build")
			.run
			
		new File(projectFolder, 'build/xtend/main/HelloWorld.java').shouldExist
		new File(projectFolder, 'build/xtend/main/.HelloWorld.java._trace').shouldExist
	}
	
	def void setContent(File file, CharSequence content) {
		file.parentFile.mkdirs
		file.createNewFile
		Files.write(content, file, Charsets.UTF_8)
	}
	
	def shouldExist(File file) {
		Assert.assertTrue(file.exists)
	}
}