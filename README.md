Xtext Gradle Plugins
====================

A set of [Gradle](https://gradle.org) plugins to build and use [Xtext](https://xtext.org) languages and the [Xtend](https://xtend-lang.org) programming language.

The documentation is hosted on the [project's website](https://xtext.github.io/xtext-gradle-plugin/).

Requirements
------------

| | Supported |
|---|---|
| Gradle | **9.8.1** or later (requires a JVM 21+ Gradle daemon) |
| Java | **21** |
| Xtext / Xtend | **2.41.0** or later |

Gradle 7 and 8 are no longer supported; use the 4.x plugin releases with those.

Note that all Xtend artifacts (`org.eclipse.xtend:*`) are published under the
`org.eclipse.xtext` group. The old coordinates relocate, and this plugin still
version-aligns both groups to `xtext.version`; new builds should prefer the
`org.eclipse.xtext` coordinates.

Building
--------

Run `./gradlew pTML -PreleaseVersion=<version>`, e.g. with `<version>` set to
`5.0.0-SNAPSHOT`. This publishes to your local Maven repository for local consumption.

`./gradlew build` runs the unit tests plus both integration matrices
(Gradle 9.8.1 with the minimum and the latest Xtext release).