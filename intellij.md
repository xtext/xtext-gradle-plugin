---
layout: default
title: IntelliJ Builder
weight: 30
---

The Xtext IDEA build system
===========================

This plugin builds [IntelliJ IDEA](https://www.jetbrains.com/idea/) plugins for [Xtext](http://xtext.org) languages. It is automatically added to your build if you choose 'IntelliJ support' in the Xtext wizard.

Usage
-----

IDEA plugins are Java projects, so the usual tasks are available

- `test` runs all your unit tests
- `assemble` creates the shippable build outputs

You will notice that IntelliJ IDEA and required plugins are downloaded automatically. They are extracted into your Gradle user home directory.

The build output includes an `ideaZip`, which packages your plugin in the [format](https://confluence.jetbrains.com/display/IDEADEV/IntelliJ+IDEA+Plugin+Structure) that the IDEA plugin manager understands.

Apart from the usual Java build tasks, you also get the `runIdea` task, which

- starts IntelliJ IDEA with your plugin installed.
- starts in debug mode if you pass the  `--debug-jvm` option
- can be configured like any other [JavaExec](http://gradle.org/docs/current/dsl/org.gradle.api.tasks.JavaExec.html) task

The plugin also integrates with 'gradle eclipse' and 'gradle idea' and adds the IntelliJ dependencies to your IDE's classpath.

Syntax
------

The following snippet explains the syntax elements of the plugin.

```groovy
plugins {
	id 'org.xtext.idea-plugin' version '2.0.1'
}

ideaDevelopment {
	//pick a version from https://www.jetbrains.com/intellij-repository/releases
	ideaVersion = '143.381.42'
	pluginRepositories {
		//you can reference idea plugin repositories, like the on of Xtext
		url 'http://download.eclipse.org/modeling/tmf/xtext/idea/2.9.0/updatePlugins.xml'
	}
	pluginDependencies {
	 	//you can have external dependencies fetched from above repositories
		id 'org.eclipse.xtext.idea' version '2.9.0'
		//or depend on plugins that are shipped with IDEA
		id 'junit'
	}
}
```


Advanced use cases
------------------

### I want to test against an existing IntelliJ installation
Leave out the ideaVersion and specify a path instead.

```groovy
ideaDevelopment {
	ideaHome = '<path to your IDEA or Android Studio installation>'
}
```

###I want to build several IDEA plugins in one build
You can have a (parent) project that is not a plugin itself, but references other plugins.

```groovy
plugins {
	id 'org.xtext.idea-development' version '2.0.1'
}

ideaDevelopment {
	pluginDependencies {
		//projects to be included when you call 'runIdea'
		project 'project1'
		project 'project2'
	}
}
```

###I want to publish an IntelliJ Enterprise Repository

```groovy
plugins {
	id 'org.xtext.idea-repository' version '2.0.1'
}

ideaRepository.rootUrl = '<the URL to which you will upload the ideaRepository folder>'
```

This adds the `ideaRepository` task. It collects all `ideaZip`s from this project and all refrenced plugin projects and creates an [updatePlugins.xml](http://blog.jetbrains.com/idea/2008/03/enterprise-plugin-repository/) descriptor.
