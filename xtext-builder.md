---
layout: default
title: Xtext Builder
weight: 10
---

Xtext Builder Plugin
====================

A Gradle Plugin for using [Xtext](http://xtext.org)-based code generators. Get the latest version from the [Plugin Portal](http://plugins.gradle.org/plugin/org.xtext.builder)


Features
--------

- Incrementally generates code based on changed files
- Allows multiple languages to cross-reference each other
- Enhances Java classes with debug information when using Xbase languages
- Hooks into 'gradle eclipse', so your languages are configured correctly when you import your projects
- Supports Gradle 4.7 and above (tested up to 7.2)
- Supports Xtext 2.9 and above (tested up to 25.0) 

Minimal Example
---------------

Below is the minimal configuration for a language that does not integrate with Java. One Xtext generator task is created for every SourceSet.

```groovy
  plugins {
    id 'org.xtext.builder' version '3.0.2'
  }

  repositories {
    jcenter()
  }

  dependencies {
    xtextLanguages 'org.example:org.example.herolang:3.3.3'
  }

  xtext {
    languages {
      herolang {
        fileExtensions = ['hero'] // required, unless fileExtension == language name (here "herolang")
        setup = 'org.example.herolang.HerolangStandaloneSetup'
      }
    }
    sourceSets {
      main {
        srcDir 'src/main/heroes'
      }
    }
  }
```

Java Integration
----------------

If you apply the Java plugin, an Xtext Generator task is created for every Java SourceSet. The Java compiler task is set to depend on this Generator task. The compile dependencies of the SourceSet are also available to the DSL files. If your languages produce Java code, their debug information is automatically installed into the class files after Java compilation.

```groovy
  plugins {
    id 'org.xtext.builder' version '3.0.2'
    id 'java'
  }

  repositories {
    jcenter()
  }

  dependencies {
    xtextLanguages 'org.example:org.example.mydsl:3.3.3'
  }

  xtext {
    languages {
      mydsl {
        setup = 'org.example.mydsl.MyDslStandaloneSetup'
        generator.outlet.producesJava = true
      }
    }
  }
```

Eclipse Integration
-------------------

If you apply the `eclipse` plugin, Xtext will configure the output folders and other preferences to match your Gradle settings.


Configuration Options Overview
------------------------------

Below is a more elaborate example with two hypothetical languages that makes use of all the current configuration options of the plugin.

```groovy
  plugins {
    id 'org.xtext.builder' version '3.0.2'
    id 'java'
  }

  repositories {
    jcenter()
  }

  dependencies {
    xtextLanguages 'org.example:org.example.herolang:3.3.3'
    xtextLanguages 'org.example:org.example.mydsl:1.2.3'
  }

  xtext {
    //Xtext version, can be omitted if Xtext is found on the classpath already
    version = '2.26.0'
    //
    languages {
      //a language configuration can be very simple, everything has good defaults
      myDsl {//the language's name
        //the Setup class to use when creating the language's compiler infrastructure
        setup = org.example.mydsl.MyDslStandaloneSetup
      }

      //but you can also customize everything to your liking
      herolang {
        setup = 'org.example.herolang.HerolangStandaloneSetup'
        /*
        * Your language's qualifiedName, if it cannot be determined
        * by removing 'StandaloneSetup' from the class listed under 'setup'
        */
        qualifiedName = 'org.example.herolang.HeroLanguage'
        //the file extensions for your language.
        //Equal to the language's name by default
        fileExtensions = ['hero', 'villain']
        generator {
          //whether to generate @SuppressWarnings("all"), enabled by default
          suppressWarningsAnnotation = false
          //what level of Java source code to generate
          //taken from the Java configuration automatically
          javaSourceLevel = '1.7'
          //whether to generate the @Generated annotation, disabled by default
          generatedAnnotation {
            active = true
            comment = "Copyright My Cool Company"
            includeDate = true
          }
          //the outlet configurations,
          //as defined in your languages OutputConfigurationProvider
          //the default outlet is available using the shortand 'outlet'
          outlets {
            HEROES {
            }
            VILLAINS {
              //automatically adds the output folder to the Java source folders
              producesJava = true
              //only generate sources once and never overwrite or delete them
              cleanAutomatically = false
            }
          }
        }
        debugger {
          //how to install debug info into generated Java code
          //SMAP is recommended in most cases
          //PRIMARY makes Xtext the only debug info (throws away Java line numbers)
          sourceInstaller = 'SMAP' //or 'PRIMARY' or 'NONE'
          //whether to hide synthetic variables in the debugger
          hideSyntheticVariables = true
        }
        validator {
          //adjust severities of issues
          //take the issue codes from the language's validator class
          error 'something.you.consider.really.Bad'
          warning 'something.Phishy'
          ignore 'some.warning.you.dont.care.About'
        }
        //you can add arbitrary key-value pairs to the preferences
        preferences my_special_preference_key: true
      }
    }

    sourceSets {
      main {
        //you can add additional folders that are not Java source folders here
        srcDir 'src/main/heroes'
        output {
          //adjust output directories per sourceSet and outlet
          //the syntax for this will improve in future releases
          //default here would be 'build/herolang/heroes/main'
          dir(xtext.languages.herolang.generator.outlets.HEROES, 'build/someSpecialDir')
        }
      }
    }
  }
```

Creating a Plugin for your Language
-----------------------------------

If you are the maintainer of an Xtext language, do you users a favor and create a reusable [Gradle plugin](https://docs.gradle.org/current/userguide/custom_plugins.html). Publish it on the [Gradle plugin portal](https://plugins.gradle.org/docs/submit), so your users don't have to copy-paste the configuration into all their build scripts. This way, for most cases the user doesn't even need to know that your language uses Xtext.

This is how a plugin for a simple Xtext language could look like (written in Xtend):

```xtend
package org.mylang.gradle

import org.gradle.api.*
import org.xtext.gradle.*
import org.xtext.gradle.tasks.*

class MyLangPlugin implements Plugin<Project> {
  override apply(Project project) {
    project.apply[plugin(XtextBuilderPlugin)]
    val xtext = project.extensions.getByType(XtextExtension)
    xtext.languages.maybeCreate("myLang") => [
      setup = "org.example.myLang.MyLangStandaloneSetup"
    ]
  }
}
```

And this is how easy it would be for your users to consume:

```groovy
plugins {
  id 'org.example.mylang' version = '1.2.3'
}
```
