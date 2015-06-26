package org.xtext.builder.standalone;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.build.BuildRequest.IPostValidationCallback;
import org.eclipse.xtext.validation.Issue;
import org.gradle.api.logging.Logger;

public class GradleValidatonCallback implements IPostValidationCallback {

	private Logger logger;
	private boolean errorFree = true;
	
	public GradleValidatonCallback(Logger logger) {
		this.logger = logger;
	}

	@Override
	public boolean afterValidate(URI validated, Iterable<Issue> issues) {
		for (Issue issue : issues) {
			switch(issue.getSeverity()) {
			case ERROR:
				logger.error(issue.toString());
				errorFree = false;
				break;
			case WARNING:
				logger.warn(issue.toString());
				break;
			case INFO:
				logger.info(issue.toString());
				break;
			case IGNORE:
				logger.debug(issue.toString());
				break;
			default:
				break;
			}
		}
		return errorFree;
	}

	public boolean isErrorFree() {
		return errorFree;
	}

}
