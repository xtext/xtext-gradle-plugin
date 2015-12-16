package org.xtext.gradle.test

import org.eclipse.core.internal.preferences.EclipsePreferences
import org.junit.Test
import org.xtext.gradle.tasks.internal.XtextEclipsePreferences

import static org.junit.Assert.*

class WhenTheEclipsePluginIsApplied extends AbstractIntegrationTest {

	override setup() {
		super.setup
		buildFile << '''
			apply plugin: 'java'
			apply plugin: 'eclipse'
			apply plugin: 'org.xtext.builder'
			
			xtext {
				version = '2.9.0'
				languages {
					xtend {
						setup = 'org.eclipse.xtend.core.XtendStandaloneSetup'
						generator {
							outlet {
								producesJava = true
							}
							javaSourceLevel = '1.6'
						}
						validator {
							error 'org.eclipse.xtend.some.some.issue'
						}
						preferences('org.eclipse.xtend.some.pref' : true)
					}
				}
			}
		'''
		file('src/main/java').mkdirs
		file('src/test/java').mkdirs
	}

	@Test
	def void properSettingsAreGenerated() {
		// when
		build('eclipse')
		
		// then
		file('.settings/org.eclipse.xtend.core.Xtend.prefs').shouldExist
		val prefs = new XtextEclipsePreferences(projectDir, 'org.eclipse.xtend.core.Xtend')
		prefs.load

		prefs.shouldContain('BuilderConfiguration.is_project_specific', true)
		prefs.shouldContain('ValidatorConfiguration.is_project_specific', true)
		prefs.shouldContain('generateSuppressWarnings', true)
		prefs.shouldContain('generateGeneratedAnnotation', false)
		prefs.shouldContain('includeDateInGenerated', false)
		prefs.shouldContain('useJavaCompilerCompliance', false)
		prefs.shouldContain('targetJavaVersion', 'Java6')
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.userOutputPerSourceFolder', true)
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.installDslAsPrimarySource', false)
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.hideLocalSyntheticVariables', true)
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.sourceFolder.src/main/java.directory', 'build/xtend/main')
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.sourceFolder.src/test/java.directory', 'build/xtend/test')

		prefs.shouldContain('org.eclipse.xtend.some.some.issue', 'error')
		prefs.shouldContain('org.eclipse.xtend.some.pref', 'true')
	}
	
	@Test
	def void settingsAreCleanedProperly() {
		// given
		build('eclipse')
		
		// when
		build('cleanEclipse')
		
		// then
		file('.settings/org.eclipse.xtend.core.Xtend.prefs').shouldNotExist
	}

	def shouldContain(EclipsePreferences prefs, String key, Object value) {
		assertEquals(value.toString, prefs.get(key, null))
	}
}

