package org.xtend.gradle.idea

import static org.junit.Assert.*
import org.junit.Test
import java.io.File
import org.xtext.gradle.idea.IdeaPluginPluginUtil

class IdeaPluginPluginUtilTest {

  @Test
  def void testGetArtifactId() {
    var file = new File("util.jar");
    assertEquals("util", IdeaPluginPluginUtil.getArtifactId(file))

    file = new File("util-core-factory.jar")
    assertEquals("util-core-factory", IdeaPluginPluginUtil.getArtifactId(file))
    file = new File("util-core-factory-1.2.3.jar")
    assertEquals("util-core-factory", IdeaPluginPluginUtil.getArtifactId(file))
    file = new File("util-core-factory-1.2.3-v123.jar")
    assertEquals("util-core-factory", IdeaPluginPluginUtil.getArtifactId(file))

    file = new File("org.eclipse.emf.core.jar")
    assertEquals("org.eclipse.emf.core", IdeaPluginPluginUtil.getArtifactId(file))
    file = new File("org.eclipse.emf.core-2.12.0.jar")
    assertEquals("org.eclipse.emf.core", IdeaPluginPluginUtil.getArtifactId(file))
    file = new File("org.eclipse.emf.core-2.12.0-v123.jar")
    assertEquals("org.eclipse.emf.core", IdeaPluginPluginUtil.getArtifactId(file))
  }

  @Test
  def void testHasSameArtifactIds() {
    var file1 = new File("util.jar");
    var file2 = new File("util-1.2.3.jar")
    assertTrue(IdeaPluginPluginUtil.hasSameArtifactIdAs(file1, file2))

    file2 = new File("util-core-factory.jar")
    assertFalse(IdeaPluginPluginUtil.hasSameArtifactIdAs(file1, file2))

    file2 = new File("util-core-factory-2.1.2.jar");
    assertFalse(IdeaPluginPluginUtil.hasSameArtifactIdAs(file1, file2))

    file1 = new File("util-core-factory.jar")
    assertTrue(IdeaPluginPluginUtil.hasSameArtifactIdAs(file1, file2))

    file1 = new File("org.eclipse.emf.core-2.12.0.jar")
    file2 = new File("org.eclipse.emf.core-2.12.0-v123.jar")
    assertTrue(IdeaPluginPluginUtil.hasSameArtifactIdAs(file1, file2))

    file1 = new File("org.eclipse.emf.core.xml")
    file2 = new File("org.eclipse.emf.core.jar")
    assertFalse(IdeaPluginPluginUtil.hasSameArtifactIdAs(file1, file2))
  }
}