The Xtext IDEA build system
===========================

This set of Gradle plugins builds Xtext DSLs for IntelliJ IDEA.

It automates the following tasks

- downloading an IntelliJ IDEA SDK and including its libraries in the build
- downloading and unpacking other IDEA plugins that you depend on
- creating an isolated sandbox to test your plugins
- running and debugging your plugin
- packaging your plugin in the ZIP format that IntelliJ's update manager understands

The basics
----------

The following build script contains the basic configuration you will need to get started.

```gradle
plugins {
	id 'org.xtext.idea-plugin' version '0.3.11'
	id 'eclipse'
}

repositories {
	jcenter()
	//Xtext 2.9 is not yet released, so we need sonatype snapshots
	maven {	url "https://oss.sonatype.org/content/repositories/snapshots/" }
}

dependencies {
	compile project('name of your dsl runtime project')
}

ideaDevelopment {
	//pick an IDEA build from https://teamcity.jetbrains.com/viewType.html?buildTypeId=bt410
	ideaVersion = '141.178.9'
	pluginRepositories {
		//Xtext IDEA plugin nightly builds
		url 'https://hudson.eclipse.org/xtext/job/xtext-intellij/lastSuccessfulBuild/artifact/git-repo/intellij/build/ideaRepository/updatePlugins.xml'
	}
	pluginDependencies {
		id 'org.eclipse.xtext.idea'
	}
}
```

IDEA plugins are Java projects, so the usual tasks are available

- `eclipse` generates Eclipse metadata like .project and .classpath, including the IntelliJ libraries
- `test` runs all your unit tests
- `assemble` creates the shippable build outputs
 - this includes an`ideaZip`, which packages your plugin in the [format](https://confluence.jetbrains.com/display/IDEADEV/IntelliJ+IDEA+Plugin+Structure) that the IDEA plugin manager understands

Apart from the usual Java build tasks, you also get

- `runIdea`
	- starts IntelliJ IDEA with your plugin installed.
	- if you pass the `--debug-jvm` option, the VM will start in debug mode
	- if you pass the `--debug-builder-process` option, IDEA's external builder process will be run in debug mode
	- see [JavaExec](http://gradle.org/docs/current/dsl/org.gradle.api.tasks.JavaExec.html) for more options

Advanced use cases
------------------

### I want to test against an existing IntelliJ installation
Leave out the ideaVersion and specify a path instead
```gradle
ideaDevelopment {
	ideaHome = '<path to your IDEA or Android Studio installation>'
}
```

###I want to build several IDEA plugins in one build
Apply the `org.xtext.idea-aggregator` plugin to the parent project. This adds an aggregated runIdea task that starts IntelliJ with all your plugins installed.

###I want to publish an IntelliJ Enterprise Repository
Apply the `org.xtext.idea-repository` plugin. This adds the `ideaRepository` task. It collects all `ideaZip`s from this project and all subprojects and creates an [updatePlugins.xml](http://blog.jetbrains.com/idea/2008/03/enterprise-plugin-repository/) descriptor.
Be sure to supply a root URL for the repository

```gradle
ideaRepository.rootUrl = '<the URL to which you will upload the ideaRepository folder>'
```

Limitations
-----------

- the plugin does not yet detect an update to the 'ideaVersion' property. You'll have to clear out the ideaHome folder yourself to force a re-download.
- plugin dependencies are currently unversioned
