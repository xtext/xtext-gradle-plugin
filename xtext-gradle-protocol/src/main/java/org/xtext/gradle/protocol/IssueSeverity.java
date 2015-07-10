package org.xtext.gradle.protocol;

public enum IssueSeverity {
	ERROR,
	WARNING,
	INFO,
	IGNORE;
	
	public String toString() {
		return name().toLowerCase();
	};
}
