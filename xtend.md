---
layout: default
title: Xtend Compiler
weight: 20
---

Xtend Compiler
===================

A Gradle plugin for compiling [Xtend](http://xtend-lang.org) source code.

Getting Started
------

Apply the latest [org.xtext.xtend](http://plugins.gradle.org/plugin/org.xtext.xtend) or [org.xtext.android.xtend](http://plugins.gradle.org/plugin/org.xtext.android.xtend) plugin. Then add the Xtend library.

```groovy
plugins {
  id "org.xtext.xtend" version "2.0.8"
}

repositories.jcenter()

dependencies {
  compile 'org.eclipse.xtend:org.eclipse.xtend.lib:2.22.0'
}
```

Features
--------

- Incrementally compiles Xtend sources to Java
- Enhances Java classes with Xtend debug information
- Integrates seamlessly with the [Xtext Builder](xtext-builder.html) plugin and other Xtext languages
- Supports both normal Java projects and the new Android build system
- Hooks into 'gradle eclipse', so the Xtend compiler is configured for your project when you import it into Eclipse

Options
--------

The Xtend plugin comes with good default settings that will suit most projets. But you can customize every aspect:

```groovy
xtend {
  generator {
    //whether to generate @SuppressWarnings("all"), enabled by default
    suppressWarningsAnnotation = false
    //whether to generate the @Generated annotation, disabled by default
    generatedAnnotation {
      active = true
      comment = "Copyright My Cool Company"
      includeDate = true
    }
  }
  debugger {
    //how to install debug info into generated Java code
    //SMAP adds Xtend debug info on top of Java
    //PRIMARY makes Xtend the only debug info (throws away Java line numbers)
    //default is SMAP for Java projects and PRIMARY for Android
    sourceInstaller = 'SMAP' //or 'PRIMARY' or 'NONE'
    //whether to hide synthetic variables in the debugger
    hideSyntheticVariables = true
  }
  validator {
    //adjust severity of issues
    //available levels are error, warning, info and ignore
    error 'org.eclipse.xtend.core.validation.IssueCodes.unused_private_member'
    // These issue IDs can be found in your Eclipse project's .settings/org.eclipse.xtend.core.Xtend.prefs
    // after enabling Project > Properties > Xtend > Errors/Warnings: [X] Enable project specific settings
  }
}
```

The output folder can be configured for each sourceSet. By default it will be `build/xtend/<sourceSet.name>`.

```groovy
sourceSets {
  main.xtendOutputDir = 'xtend-gen'
  test.xtendOutputDir = 'test/xtend-gen'
}
```
