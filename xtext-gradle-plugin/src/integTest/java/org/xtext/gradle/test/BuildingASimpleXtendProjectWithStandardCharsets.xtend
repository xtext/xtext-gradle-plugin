package org.xtext.gradle.test

import com.google.common.io.Files
import java.nio.charset.Charset
import java.util.Collection
import org.gradle.api.tasks.compile.JavaCompile
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import org.junit.runners.Parameterized.Parameter
import org.junit.runners.Parameterized.Parameters
import org.xtext.gradle.tasks.XtextGenerate

import static java.nio.charset.StandardCharsets.*

@RunWith(Parameterized)
class BuildingASimpleXtendProjectWithStandardCharsets extends AbstractIntegrationTest {

	@Parameters(name="{0}")
	static def Collection<Object[]> standardCharsets() {
		return #[
			#[US_ASCII],
			#[ISO_8859_1],
			#[UTF_8],
			#[UTF_16BE],
			#[UTF_16LE],
			#[UTF_16]
		]
	}

	@Parameter
	public Charset charset

	@Test
	def void canCompileWithCharset() {
		// given
		buildFile << '''
			«xtendPluginSnippet»
			tasks.withType(«XtextGenerate.name») {
				encoding = "«charset.name»"
			}
			tasks.withType(«JavaCompile.name») {
				options.encoding = "«charset.name»"
			}
		'''
		file('src/main/java/HelloWorld.xtend') => [
			parentFile.mkdirs
			createNewFile
			Files.write('''class HelloWorld {}''', it, charset)
		]

		// expect: no error
		build('build')
	}

}