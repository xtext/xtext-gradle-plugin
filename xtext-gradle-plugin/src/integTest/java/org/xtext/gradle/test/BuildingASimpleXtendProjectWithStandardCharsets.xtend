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

import static java.nio.charset.StandardCharsets.*
import static org.junit.Assert.*

@RunWith(Parameterized)
class BuildingASimpleXtendProjectWithStandardCharsets extends AbstractXtendIntegrationTest {

	static val asciiHelloWorld = '''helloWorld = "Hello World!"'''
	static val helloWorld = '''你好世界 = "ওহে বিশ্ব!"'''

	@Parameters(name="{0} with {1}")
	static def Collection<Object[]> standardCharsets() {
		return #[
			#[US_ASCII, asciiHelloWorld, true],
			#[US_ASCII, helloWorld, false],
			#[ISO_8859_1, asciiHelloWorld, true],
			#[ISO_8859_1, helloWorld, false],
			#[UTF_8, helloWorld, true],
			#[UTF_16BE, helloWorld, true],
			#[UTF_16LE, helloWorld, true],
			#[UTF_16, helloWorld, true]
		]
	}

	@Parameter
	public Charset charset

	@Parameter(value=1)
	public String variableDeclaration

	@Parameter(value=2)
	public boolean expectSuccess

	@Test
	def void canCompileWithCharset() {
		// given
		buildFile << '''
			«xtendPluginSnippet»
			tasks.withType(«JavaCompile.name») {
				options.encoding = "«charset.name»"
			}
		'''
		file('src/main/java/HelloWorld.xtend') => [
			parentFile.mkdirs
			createNewFile
			Files.asCharSink(it, charset).write('''
				class HelloWorld {
					val «variableDeclaration»
				}
			''')
		]

		if (expectSuccess) {
			// when
			build('build')
			// then
			val fileContent = Files.asCharSource(file('build/xtend/main/HelloWorld.java'), charset).read
			assertTrue(fileContent.contains('''private final String «variableDeclaration»;'''))
		} else {
			// expect: build failure
			buildAndFail('build')
		}
	}

}