package org.xtext.gradle.test

import org.junit.Ignore
import org.junit.Test

class BuildingASimpleXtendProject extends AbstractXtendIntegrationTest {

    @Test
	def theGeneratorShouldRunAndCompileWhenInvokedInSeperateBuilds() {
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("generateXtext")
		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist

		build("compileJava")

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist
	}

	@Test
	def theGeneratorShouldRunAndCompileWhenInvokedInSeperateBuildsWithJavaPackage() {
		file('src/main/java/org/xtext/it/HelloWorld.xtend').content = '''
			package org.xtext.it
			class HelloWorld {}
		'''

		build("generateXtext")
		file('build/xtend/main/org/xtext/it/HelloWorld.java').shouldExist
		file('build/xtend/main/org/xtext/it/.HelloWorld.java._trace').shouldExist

		build("compileJava")

		file('build/xtend/main/org/xtext/it/HelloWorld.java').shouldExist
		file('build/xtend/main/org/xtext/it/.HelloWorld.java._trace').shouldExist
	}
	
	@Test
	def theGeneratorShouldRunOnValidInput() {
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("build")

		file('build/xtend/main/HelloWorld.java').shouldExist
		file('build/xtend/main/.HelloWorld.java._trace').shouldExist
	}

	@Test
	def theGeneratorShouldNotRunWhenAllFilesAreUpToDate() {
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		build("build")
		val secondResult = build("build")
		secondResult.xtextTask.shouldBeUpToDate
	}

	@Test
	def theGeneratorShouldOnlyRunForAffectedFiles() {
		val upStream = createFile('src/main/java/UpStream.xtend', '''
			class UpStream {}
		''')
		val downStream = createFile('src/main/java/DownStream.xtend', '''
			class DownStream {
				UpStream upStream
			}
		''')
		val unrelated = createFile('src/main/java/Unrelated.xtend', '''
			class Unrelated {}
		''')

		build("build")

		upStream.content = '''
			class UpStream {
				def void foo() {}
			}
		'''
		val secondResult = build("build", "-i")

		secondResult.hasRunGeneratorFor(upStream)
		secondResult.hasRunGeneratorFor(downStream)
		secondResult.hasNotRunGeneratorFor(unrelated)
	}
	
	@Test
	def affectedResourcesAreDetectedAcrossXtendAndJava() {
		val upStream = createFile('src/main/java/A.xtend', '''
			class A {}
		''')
		createFile('src/main/java/B.java', '''
			public class B extends A {
			}
		''')
		val downStream = createFile('src/main/java/C.xtend', '''
			class C extends B {}
		''')

		build("build")

		upStream.content = '''
			class A {
				def void foo() {}
			}
		'''
		val secondResult = build("build", "-i")

		secondResult.hasRunGeneratorFor(upStream)
		secondResult.hasRunGeneratorFor(downStream)
	}
	
	@Test
	def void builtInActiveAnnotationsWork() {
		file('src/main/java/HelloWorld.xtend').content = '''
			import org.eclipse.xtend.lib.annotations.Data
			
			@Data 
			class HelloWorld {
				String greeting
				def test() {
					getGreeting
				}
			}
		'''

		build("generateXtext")
	}
	
	@Test
	def void shouldCompileAfterErrorIsFixed() {
		// given
		val file = createFile('src/main/java/HelloWorld.xtend', '''
			class HelloWorld {
				
				def void helloWorld() {
					println "This is Groovy syntax"
				}
				
			}
		''')
		buildAndFail('build')
		
		// expect: no failure
		file.content = '''
			class HelloWorld {
				
				def void helloWorld() {
					println("This is Xtend syntax")
				}
				
			}
		'''
		build('build')
	}
	
	@Test
	def void classFilesAreGenerated() {
		// given
		file('src/main/java/HelloWorld.xtend').content = '''
			class HelloWorld {}
		'''

		// when
		build('build')

		// then
		file('build/classes/main/HelloWorld.class').shouldExist
	}
	
	@Test
	def void classFilesAdhereToPackageStructure() {
		// given
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''

		// when
		build('build')

		// then
		file('build/classes/main/com/example/HelloWorld.class').shouldExist
	}
	
	@Test
	def void theOutputFolderCanBeConfigured() {
		buildFile << '''
			sourceSets.main.xtendOutputDir = "build/xtend-gen"
		'''
		// given
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''

		// when
		build('build')

		// then
		file('build/xtend-gen/com/example/HelloWorld.java').shouldExist
		file('build/classes/main/com/example/HelloWorld.class').shouldExist
	}
	
    @Test
	def void theOutputIsCleanedOnAFullBuild() {
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''
		val staleFile = file('build/xtend/main/com/example/Foo.java')
		staleFile.content = '''
			package com.example;
			public class Foo {}
		'''

		// when
		build('build')

		// then
		staleFile.shouldNotExist
	}
	
	@Test
	def void theOutputIsCleanedWhenCallingGradleClean() {
		val staleFile = file('build/xtend/main/com/example/Foo.java')
		staleFile.content = '''
			package com.example;
			public class Foo {}
		'''

		// when
		build('cleanGenerateXtext')

		// then
		staleFile.shouldNotExist
	}
	
	@Ignore("Doesn't work if we want to keep @SkipWhenEmpty on the XtextGenerate sources")
	@Test
	def void theOutputIsCleanedWhenTheLastXtendFileIsRemoved() {
		val staleFile = file('build/xtend/main/com/example/Foo.java')
		staleFile.content = '''
			package com.example;
			public class Foo {}
		'''

		// when
		build('cleanGenerateXtext')

		// then
		staleFile.shouldNotExist
	}
	
 	@Test
	def void theIndexerCanHandleNonExistentClasspathEntries() {
		file('src/test/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''

		build("build")
	}

 	@Test
	def void theIndexerCanHandleDirectoryClasspathEntries() {
		file('src/main/java/com/example/Foo.xtend').content = '''
			package com.example
			class Foo {}
		'''
		file('src/test/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld {}
		'''

		build("build")
	}
	
 	@Test
	def void theJavaSourceAndXtend() {
		file('src/main/java/com/example/Foo.java').content = '''
			package com.example;
			class Foo {}
		'''
		file('src/test/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			class HelloWorld extends Foo {}
		'''

		build("build")
	}
	
 	@Test
	def void theJavaSourceAndXtend_01() {
		file('src/main/java/com/example/bla/ResourceServiceProvider.java').content = '''
			package com.example.bla;
			public interface ResourceServiceProvider {
			    public java.util.List<? extends IEObjectDescription> getDescriptions();
			}
		'''
		file('src/main/java/com/example/bla/IEObjectDescription.java').content = '''
			package com.example.bla;
			public interface IEObjectDescription {
			    ResourceServiceProvider getEObject();
			}
		'''
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			
			import com.example.bla.*
			
			class HelloWorld {
			    
			    def void foo(ResourceServiceProvider provider) {
			        for (e : provider.descriptions) {
			            println(e.EObject)
			        }
			    }
			}
		'''

		build("build")
	}
	
 	@Test
	def void theJavaSourceAndXtend_02() {
		file('src/main/java/com/example/bla/ResourceServiceProvider.java').content = '''
			package com.example.bla;
			public interface ResourceServiceProvider {
			    public java.util.List<? extends IEObjectDescription> getDescriptions();
			}
		'''
		file('src/main/java/com/example/bla/IEObjectDescription.java').content = '''
			package com.example.bla;
			public interface IEObjectDescription {
			    ResourceServiceProvider getEObject();
			}
		'''
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			
			import com.example.bla.*
			
			class HelloWorld implements ResourceServiceProvider {
			    
			    override getDescriptions() {
			        return #[]
			    }
			    
			    def void foo() {
			        for (x : descriptions) {
			            print(x.EObject.descriptions.head)
			        }
			    }
			}
		'''

		build("build")
	}
	
 	@Test
	def void theJavaSourceAndXtend_03() {
		file('src/main/java/com/example/bla/ResourceServiceProvider.java').content = '''
			package com.example.bla;
			public interface ResourceServiceProvider {
			    public java.util.List<? extends IEObjectDescription> getDescriptions();
			}
		'''
		file('src/main/java/com/example/bla/IEObjectDescription.java').content = '''
			package com.example.bla;
			public interface IEObjectDescription {
			    ResourceServiceProvider getEObject();
			}
		'''
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			
			import com.example.bla.*
			
			class HelloWorld implements ResourceServiceProvider {
			    
			    override getDescriptions() {
			        return #[]
			    }
			    
			    def void foo() {
			        for (x : descriptions) {
			            print(x.EObject.descriptions.head)
			        }
			    }
			}
		'''

		build("build")
	}
	
 	@Test
	def void theJavaSourceAndXtend_04() {
		file('src/main/java/org/eclipse/xtext/validation/IResourceValidator.java').content = '''
			package org.eclipse.xtext.validation;
			
			import java.util.Collections;
			import java.util.List;
			
			@SuppressWarnings("")
			public interface IResourceValidator {
			    
			    List<Issue> validate(String resource, String mode, String indicator) throws IllegalArgumentException;
			
			    IResourceValidator NULL = new IResourceValidator() {
			        @Override
			        public List<Issue> validate(String resource, String mode, String indicator) {
			            return Collections.emptyList();
			        }
			    };
			}

		'''
		file('src/main/java/org/eclipse/xtext/validation/Issue.java').content = '''
			package org.eclipse.xtext.validation;
			public interface Issue {
			    public String sayHello();
			}
		'''
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			
			import org.eclipse.xtext.validation.IResourceValidator
			
			@SuppressWarnings("")
			interface IShouldGenerate {
			    
			    def boolean shouldGenerate(String resource, String cancelIndicator);
			    
			    @SuppressWarnings("")
			    static class OnlyWithoutErrors implements IShouldGenerate {
			        
			        @SuppressWarnings("") IResourceValidator resourceValidator
			        
			        override shouldGenerate(String resource, String cancelIndicator) {
			            if (!resource.isNullOrEmpty)
			                return false
			            val issues = resourceValidator.validate(resource, "CheckMode.NORMAL_AND_FAST", cancelIndicator)
			            return !issues.exists[sayHello == 'Severity.ERROR']
			        }
			        
			    }
			    
			    @SuppressWarnings("")
			    static class Always implements IShouldGenerate {
			        
			        override shouldGenerate(String resource, String cancelIndicator) {
			            return true
			        }
			        
			    }
			}
		'''

		build("build")
	}
	
	@Ignore("unignore me once 2.11.0.beta3 is out")
 	@Test
	def void theJavaSourceAndXtend_05() {
		file('src/main/java/org/eclipse/xtext/validation/IFoo.java').content = '''
			package org.eclipse.xtext.validation;
			
			import java.util.Collections;
			import java.util.List;
			
			public interface IFoo {
			    
			    List<Issue> doStuff(String resource, String mode, String indicator);
			}

		'''
		file('src/main/java/org/eclipse/xtext/validation/IFoo2.java').content = '''
			package org.eclipse.xtext.validation;
			
			import java.util.Collections;
			import java.util.List;
			
			public interface IFoo2 extends IFoo {
			    
			    @Override
			    List<Issue> doStuff(String resource, String mode, String indicator);
			}

		'''
		file('src/main/java/org/eclipse/xtext/validation/Issue.java').content = '''
			package org.eclipse.xtext.validation;
			public interface Issue {
			    public String sayHello();
			}
		'''
		file('src/main/java/com/example/HelloWorld.xtend').content = '''
			package com.example
			
			import org.eclipse.xtext.validation.IFoo2
			
			class IShouldGenerate {
			    
			    def void doStuff(IFoo2 f) {
			        for (i : f.doStuff("","","")) {
			            println(i.sayHello.length)
			        }
			    }
			    
			}
		'''

		build("build")
	}
}

