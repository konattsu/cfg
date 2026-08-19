#[derive(Debug, Default)]
pub(crate) struct Env {
    path_prepend: Vec<std::path::PathBuf>,
}

impl<'de> serde::Deserialize<'de> for Env {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        #[derive(serde::Deserialize)]
        #[serde(deny_unknown_fields)]
        struct RawEnv {
            #[serde(default)]
            path_prepend: Vec<std::path::PathBuf>,
        }

        let raw = RawEnv::deserialize(deserializer)?;
        Env::new(raw.path_prepend).map_err(serde::de::Error::custom)
    }
}

impl Env {
    fn new(path_prepend: Vec<std::path::PathBuf>) -> Result<Self, String> {
        for (index, path) in path_prepend.iter().enumerate() {
            crate::model::validations::path_string(
                path,
                &format!("env.path_prepend[{index}]"),
            )?;
        }
        Ok(Self { path_prepend })
    }

    pub(crate) fn path_prepend(&self) -> &[std::path::PathBuf] {
        &self.path_prepend
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_deserialize_path_prepend() {
        let env: Env = toml::from_str(
            r#"
path_prepend = ["~/.local/bin", "/opt/bin"]
"#,
        )
        .unwrap();

        assert_eq!(env.path_prepend().len(), 2);
    }

    #[test]
    fn test_reject_shell_expansion() {
        let error = toml::from_str::<Env>(
            r#"
path_prepend = ["$HOME/.local/bin"]
"#,
        )
        .unwrap_err();

        assert!(
            error
                .to_string()
                .contains("shell variable expansion is not supported")
        );
    }
}
