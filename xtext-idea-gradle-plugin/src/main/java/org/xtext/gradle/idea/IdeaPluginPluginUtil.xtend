package org.xtext.gradle.idea

import java.util.regex.Pattern
import java.io.File

class IdeaPluginPluginUtil {
  private static val ARTIFACT_ID = Pattern.compile("(.*?)(-[0-9].*)?\\.jar")

  public static def hasSameArtifactIdAs(File file1, File file2) {
    if (file1.artifactId !== null && file2.artifactId !== null) {
      return file1.artifactId == file2.artifactId
    }
    false
  }

  public static def getArtifactId(File file) {
    val matcher = ARTIFACT_ID.matcher(file.name)
    if (matcher.matches) matcher.group(1) else null
  }
}