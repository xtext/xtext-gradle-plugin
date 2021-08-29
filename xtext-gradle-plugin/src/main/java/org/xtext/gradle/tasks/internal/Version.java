package org.xtext.gradle.tasks.internal;

import java.util.List;

import org.gradle.internal.impldep.com.google.api.client.repackaged.com.google.common.base.Joiner;

import com.google.common.base.Splitter;

public class Version implements Comparable<Version> {

	public static Version parse(String version) {
		return new Version(Splitter.on('.').splitToList(version));
	}

	private final List<String> parts;

	private Version(List<String> parts) {
		this.parts = parts;
	}

	@Override
	public int compareTo(Version o) {
		int maxLength = Math.max(parts.size(), o.parts.size());

		for (int i = 0; i < maxLength; i++) {
			Integer v1 = i < parts.size() ? Integer.parseInt(parts.get(i)) : 0;
			Integer v2 = i < o.parts.size() ? Integer.parseInt(o.parts.get(i)) : 0;
			int comparison = v1.compareTo(v2);
			if (comparison != 0) {
				return comparison;
			}
		}
		return 0;
	}

	@Override
	public boolean equals(Object obj) {
		if (obj instanceof Version) {
			return parts.equals(((Version) obj).parts);
		}
		return false;
	}

	@Override
	public int hashCode() {
		return parts.hashCode();
	}

	@Override
	public String toString() {
		return Joiner.on('.').join(parts);
	}
}
