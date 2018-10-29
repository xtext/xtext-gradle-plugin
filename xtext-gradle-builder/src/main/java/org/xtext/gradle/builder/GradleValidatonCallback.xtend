package org.xtext.gradle.builder

import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.build.BuildRequest.IPostValidationCallback
import org.eclipse.xtext.validation.Issue
import org.gradle.api.logging.Logger
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.annotations.Accessors

@FinalFieldsConstructor
class GradleValidatonCallback implements IPostValidationCallback {
	val Logger logger
	@Accessors
	boolean errorFree = true

	override afterValidate(URI validated, Iterable<Issue> issues) {
		logger.info("Starting validation for input: '" + validated.lastSegment + "'")
		for (issue : issues) {
			switch (issue.severity) {
				case ERROR: {
					logger.error(issue.toString)
					errorFree = false
				}
				case WARNING: {
					logger.warn(issue.toString)
				}
				case INFO: {
					logger.info(issue.toString)
				}
				case IGNORE: {
					logger.debug(issue.toString)
				}
				default: {
				}
			}
		}
		return errorFree
	}
}