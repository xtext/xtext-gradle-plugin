package org.xtext.builder.standalone;

import java.util.List;
import java.util.Map;
import java.util.Set;

import org.eclipse.jdt.annotation.NonNull;
import org.eclipse.jdt.annotation.Nullable;
import org.eclipse.xtext.builder.standalone.ILanguageConfiguration;
import org.eclipse.xtext.generator.OutputConfiguration;

import com.google.common.base.Splitter;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Maps;

public class LanguageConfigurationParser {

	private Map<String, Language> languages = Maps.newHashMap();

	public void addArgument(String commandLineArgument) {
		List<String> keyValue = ImmutableList.copyOf(Splitter.on('=').split(commandLineArgument));
		String key = keyValue.get(0);
		String value = keyValue.get(1);
		List<String> path = ImmutableList.copyOf(Splitter.on('.').split(key));
		String languageName = path.get(0).replace("-L", "");
		Language language = languages.get(languageName);
		if (language == null) {
			language = new Language();
			languages.put(languageName, language);
		}
		if (path.get(1).equals("setup")) {
			language.setSetup(value);
		} else if (path.get(1).equals("javaSupport")) {
			language.setJavaSupport(Boolean.valueOf(value));
		} else {
			String outputName = path.get(1);
			OutputConfiguration output = language.getOutputs().get(outputName);
			if (output == null) {
				output = new OutputConfiguration(outputName);
				language.getOutputs().put(outputName, output);
			}
			if (path.get(2).equals("dir")) {
				output.setOutputDirectory(value);
			} else if (path.get(2).equals("createDir")) {
				output.setCreateOutputDirectory(Boolean.valueOf(value));
			} else {
				throw new IllegalArgumentException("Unknown output property " + path.get(2));
			}
		}

	}

	public List<Language> getLanguages() {
		return ImmutableList.copyOf(languages.values());
	}

	public class Language implements ILanguageConfiguration {

		private String setup;
		private boolean javaSupport = false;
		private Map<String, OutputConfiguration> outputs = Maps.newHashMap();

		@Override
		@NonNull
		public String getSetup() {
			return setup;
		}

		public void setSetup(String setup) {
			this.setup = setup;
		}

		public Map<String, OutputConfiguration> getOutputs() {
			return outputs;
		}

		@Override
		@Nullable
		public Set<OutputConfiguration> getOutputConfigurations() {
			return ImmutableSet.copyOf(outputs.values());
		}

		@Override
		public boolean isJavaSupport() {
			return javaSupport;
		}

		public void setJavaSupport(boolean javaSupport) {
			this.javaSupport = javaSupport;
		}
	}
}
