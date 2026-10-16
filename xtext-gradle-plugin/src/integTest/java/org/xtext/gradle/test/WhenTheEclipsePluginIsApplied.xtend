package org.xtext.gradle.test

import java.nio.file.Files
import java.nio.file.Paths
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

			java {
				sourceCompatibility = JavaVersion.VERSION_21
			}

			xtext {
				version = '«xtextVersion»'
				languages {
					xtend {
						setup = 'org.eclipse.xtend.core.XtendStandaloneSetup'
						generator {
							outlet {
								producesJava = true
							}
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
		build('xtextEclipseSettings')

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
		prefs.shouldContain('targetJavaVersion', 'JAVA21')
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.userOutputPerSourceFolder', true)
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.installDslAsPrimarySource', false)
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.hideLocalSyntheticVariables', true)
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.sourceFolder.src/main/java.directory', 'build/xtend/main')
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.sourceFolder.src/test/java.directory', 'build/xtend/test')

		prefs.shouldContain('org.eclipse.xtend.some.some.issue', 'error')
		prefs.shouldContain('org.eclipse.xtend.some.pref', 'true')
	}

        @Test
        def void settingsDontContainComments() {
                // when
                build('xtextEclipseSettings')

                // then
                val prefs = file('.settings/org.eclipse.xtend.core.Xtend.prefs')
                assertFalse(prefs.contentAsString.contains("#"))
        }

	/**
	 * The .settings files are owned by the user and normally committed to version control,
	 * so a clean must not remove them. They are produced from the regular task lifecycle
	 * rather than from Gradle's deprecated cleanEclipse task.
	 */
	@Test
	def void settingsSurviveClean() {
		// given
		build('xtextEclipseSettings')
		file('.settings/org.eclipse.xtend.core.Xtend.prefs').shouldExist

		// when
		build('clean')

		// then
		file('.settings/org.eclipse.xtend.core.Xtend.prefs').shouldExist
	}

	/**
	 * The settings task is hooked into the 'classes' task, which only exists once the
	 * java plugin has been applied. This plugin applies just 'base' and 'jvm-ecosystem',
	 * so a plain-language project that applies the eclipse plugin must still configure.
	 */
	@Test
	def void configurationSucceedsWithoutTheJavaPlugin() {
		// given a project that never applies the java plugin
		buildFile = '''
			plugins {
				id 'org.xtext.builder' apply false
			}
			allprojects {
				repositories {
					mavenCentral()
				}
			}
			apply plugin: 'eclipse'
			apply plugin: 'org.xtext.builder'

			xtext {
				version = '«xtextVersion»'
				languages {
					xtend {
						setup = 'org.eclipse.xtend.core.XtendStandaloneSetup'
					}
				}
			}
		'''

		// when configuring the build, which used to fail looking up 'classes'
		build('xtextEclipseSettings')

		// then
		file('.settings/org.eclipse.xtend.core.Xtend.prefs').shouldExist
	}

	/**
	 * Eclipse is configured with the source folders the build declares. If one of them is
	 * a symbolic link, the preference key must still name the declared folder rather than
	 * the link target, otherwise Eclipse shows a folder the build never mentioned.
	 */
	@Test
	def void symlinkedSourceFoldersKeepTheirConfiguredName() {
		// given src/main/java is a link to a directory outside the conventional layout
		val link = file('src/main/java')
		link.delete()
		file('shared-src').mkdirs
		Files.createSymbolicLink(link.toPath, Paths.get('../../shared-src'))

		// when
		build('xtextEclipseSettings')

		// then the key names the configured folder, not the resolved target
		val prefs = new XtextEclipsePreferences(projectDir, 'org.eclipse.xtend.core.Xtend')
		prefs.load
		prefs.shouldContain('outlet.DEFAULT_OUTPUT.sourceFolder.src/main/java.directory', 'build/xtend/main')
		assertNull(
			prefs.get('outlet.DEFAULT_OUTPUT.sourceFolder.shared-src.directory', null))
	}

	def shouldContain(EclipsePreferences prefs, String key, Object value) {
		assertEquals(value.toString, prefs.get(key, null))
	}
}

