---
layout: default
title: Xtend Compiler
weight: 20
---

Xtend Compiler
===================

A Gradle plugin for compiling [Xtend](xtend-lang.org) source code.

Getting Started
------
Apply the latest [org.xtext.xtend](http://plugins.gradle.org/plugin/org.xtext.xtend) or  [org.xtext.android.xtend](http://plugins.gradle.org/plugin/org.xtext.android.xtend) plugin. Then add the Xtend library.

```groovy
plugins {
  id "org.xtext.xtend" version "1.0.0"
}

repositories.jcenter()

dependencies {
  compile 'org.eclipse.xtend:org.eclipse.xtend.lib:2.9.0'
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

Xtend uses the Xtext Builder plugin under the hood. It is available for configuration using

```groovy
xtext {
  languages {
    xtend {
      //customizations here
    }
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
