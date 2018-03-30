---
layout: default
title: Xtext Builder
weight: 10
---

Xtext Builder Plugin
====================

A Gradle Plugin for using [Xtext](http://xtext.org)-based code generators. Get the latest version from the [Plugin Portal](http://plugins.gradle.org/plugin/org.xtext.builder)

The plugin allows any number of Xtext languages to cross-link against each other. The Generator works incrementally, only indexing, validating and generating for files that were affected by a change. It integrates well with other Gradle plugins like the Java plugin, Eclipse plugin and the Android build tools.

Minimal Example
---------------

Below is the minimal configuration for a language that does not integrate with Java. One Xtext generator task is created for every SourceSet.

```groovy
  plugins {
    id 'org.xtext.builder' version '1.0.21'
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
        fileExtension = 'hero' // required, unless fileExtension == language name (here "herolang")
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
    id 'org.xtext.builder' version '1.0.21'
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

Android Integration
-------------------
For Android integration, use the [org.xtext.android](http://plugins.gradle.org/plugin/org.xtext.android) plugin.

An Xtext Generator task is created for every Variant as well as for the tests. The Java compiler task is set to depend on this Generator task. The compile dependencies of the Variant are also available to the DSL files. If your languages produce Java code, their debug information is automatically installed into the class files after Java compilation.

```groovy
  plugins {
    id 'com.android.application' version '1.5.0'
    id 'org.xtext.android' version '1.0.21'
  }

  //repositories, dependencies and xtext configuration same as above

  android {
    //your usual android configuration
  }
```

Eclipse Integration
-------------------

If you apply the `eclipse` plugin, Xtext will configure the output folders and other preferences to match your Gradle settings.

IntelliJ Integration
--------------------

Coming soon

Configuration Options Overview
------------------------------

Below is a more elaborate example with two hypothetical languages that makes use of all the current configuration options of the plugin.

```groovy
  plugins {
    id 'org.xtext.builder' version '1.0.21'
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
    version = '2.9.0'
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
        //the file extension for your language.
        //Equal to the language's name by default
        fileExtension = 'hero'
        generator {
          //whether to generate @SuppressWarnings("all"), enabled by default
          suppressWarningsAnnotation = false
          //what level of Java source code to generate
          //taken from the Java/Android configuration automatically
          javaSourceLevel = '1.7'
          //whether to generate the @Generated annotation, disabled by default
          generatedAnnotation {
            enabled = true
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
            }
          }
        }
        debugger {
          //how to install debug info into generated Java code
          //SMAP is recommended in most cases (but Android does not support it)
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
          dir(xtext.languages.herolang.HEROES, 'build/someSpecialDir')
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
