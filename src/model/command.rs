#[derive(Debug)]
pub(crate) struct Command {
    platform: crate::model::PlatformFilter,
    run: String,
    unless: Option<String>,
    requires: Vec<String>,
}

impl<'de> serde::Deserialize<'de> for Command {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        #[derive(serde::Deserialize)]
        #[serde(deny_unknown_fields)]
        struct RawCommand {
            #[serde(default = "crate::model::default_platform_filter")]
            platform: crate::model::PlatformFilter,
            run: String,
            unless: Option<String>,
            #[serde(default)]
            requires: Vec<String>,
        }

        let raw = RawCommand::deserialize(deserializer)?;
        Command::new(raw.platform, raw.run, raw.unless, raw.requires)
            .map_err(serde::de::Error::custom)
    }
}

impl Command {
    fn new(
        platform: crate::model::PlatformFilter,
        run: String,
        unless: Option<String>,
        requires: Vec<String>,
    ) -> Result<Self, String> {
        if run.is_empty() {
            return Err("command run must be a non-empty string".to_string());
        }
        if unless.as_deref() == Some("") {
            return Err("command unless must be a non-empty string".to_string());
        }
        for required in &requires {
            if !is_valid_executable(required) {
                return Err(format!("invalid executable name \"{required}\""));
            }
        }
        Ok(Self {
            platform,
            run,
            unless,
            requires,
        })
    }

    pub(crate) fn platform(&self) -> crate::model::PlatformFilter {
        self.platform
    }
    pub(crate) fn run(&self) -> &str {
        &self.run
    }
    pub(crate) fn unless(&self) -> Option<&str> {
        self.unless.as_deref()
    }
    pub(crate) fn requires(&self) -> &[String] {
        &self.requires
    }
}

fn is_valid_executable(value: &str) -> bool {
    !value.is_empty()
        && value
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '_' | '+' | '-'))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_reject_requires_path() {
        let error = toml::from_str::<Command>(
            r#"
run = "true"
requires = ["bin/tool"]
"#,
        )
        .unwrap_err();

        assert!(error.to_string().contains("invalid executable name"));
    }

    #[test]
    fn test_reject_empty_unless() {
        let error = toml::from_str::<Command>(
            r#"
run = "true"
unless = ""
"#,
        )
        .unwrap_err();

        assert!(error.to_string().contains("command unless"));
    }
}
