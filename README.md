xtext-gradle-plugin
===================

[![Build Status](https://oehme.ci.cloudbees.com/buildStatus/icon?job=xtext-gradle-plugin)](https://oehme.ci.cloudbees.com/job/xtext-gradle-plugin/)

A plugin for using Xtext languages from a Gradle build

Features
--------

- Use Xtext based code generators in your Gradle build
- automatically integrates with the Java plugin
- all your languages are built in one go, so they can have cross-references
- configures the Eclipse plugin to generate .settings files for each language

Usage
-----

Add the plugin to your build classpath

```groovy
buildscript {
  repositories {
    mavenCentral()
  }
  dependencies {
    classpath 'org.xtext:xtext-gradle-plugin:0.0.2'
  }
}
```

Add your languages to the xtextTooling configuration

```groovy
dependencies {
  xtextTooling 'org.example:org.example.hero.core:3.3.3'
  xtextTooling 'org.example:org.example.villain.core:6.6.6'
}
```

Add code that your models compile against to the xtext configuration. If you use the Java plugin, this configuration will automatically contain everything from compile and testCompile. So in many cases this can be omitted.

```groovy
dependencies {
  xtext 'com.google.guava:guava:15.0'
}
```

Configure your languages

```groovy
xtext {
  version = '2.5.3' // the current default, can be omitted
  encoding = 'UTF-8' //the default, can be omitted
  
  /* Java sourceDirs are added automatically,
   * so you only need this element if you have
   * additional source directories to add
   */
  sources {
    srcDir 'src/main/heroes'
    srcDir 'src/main/villains'
  }
  
  languages{
    heroes {
      setup = 'org.example.hero.core.HeroStandaloneSetup'
      consumesJava = true
      outputs {
        DEFAULT_OUTPUT.dir = 'build/heroes'
        SIDEKICKS.dir = 'build/sidekicks'
      }
    }
    
    villains {
      setup = 'org.example.villain.core.VillainStandaloneSetup'
      //equivalent to DEFAULT_OUTPUT.dir
      output.dir = 'build/villains'
    }
  }
}
```
