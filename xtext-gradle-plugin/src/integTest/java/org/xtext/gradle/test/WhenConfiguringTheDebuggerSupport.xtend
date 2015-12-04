package org.xtext.gradle.test

import org.junit.Test
import org.objectweb.asm.ClassReader
import org.objectweb.asm.ClassVisitor
import org.objectweb.asm.Opcodes
import org.xtext.gradle.protocol.GradleInstallDebugInfoRequest.SourceInstaller

import static org.junit.Assert.*

class WhenConfiguringTheDebuggerSupport extends AbstractIntegrationTest {

	@Test
	def void sourcesCanBeInstalledAsSmap() {
		testSourceInstallation(SourceInstaller.SMAP)[name, info|
			assertEquals("HelloWorld.java", name)
			assertTrue(info.contains("SMAP"))
			assertTrue(info.contains("HelloWorld.xtend"))
		]
	}
	
	@Test
	def void sourcesCanBeInstalledAsPrimary() {
		testSourceInstallation(SourceInstaller.PRIMARY)[name, info|
			assertEquals("HelloWorld.xtend", name)
		]
	}
	@Test
	def void sourcesInstallationCanBeSkipped() {
		testSourceInstallation(SourceInstaller.NONE)[name, info|
			assertEquals("HelloWorld.java", name)
			assertNull(info)
		]
	}
	
	private def testSourceInstallation(SourceInstaller sourceInstaller, (String, String) => void sourceVisitor) {
		buildFile << '''
			apply plugin: 'java'
			apply plugin: 'org.xtext.builder'
			apply plugin: 'org.xtext.java'
			
			dependencies {
				compile 'org.eclipse.xtend:org.eclipse.xtend.lib:2.9.0'
				xtextTooling 'org.eclipse.xtend:org.eclipse.xtend.core:2.9.0'
			}
			
			xtext {
				version = '2.9.0'
				languages {
					xtend {
						setup = 'org.eclipse.xtend.core.XtendStandaloneSetup'
						generator {
							outlet {
								producesJava = true
							}
						}
						debugger {
							sourceInstaller = '«sourceInstaller.name»'
						}
					}
				}
			}
		'''
		createFile("src/main/java/HelloWorld.xtend", '''
			class HelloWorld {
				static def void main(String... args) {
					println("Hello")
				}
			}
		''')
		
		build("build")
		val classFile = file("build/classes/main/HelloWorld.class")
		
		classFile.shouldExist
		new ClassReader(classFile.content).accept(new ClassVisitor(Opcodes.ASM5) {
			override visitSource(String name, String info) {
				sourceVisitor.apply(name, info)
			}
		},0)
	}
}