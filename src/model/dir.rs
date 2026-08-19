#[derive(Debug)]
pub(crate) struct Dir {
    path: std::path::PathBuf,
    platform: crate::model::PlatformFilter,
    mode: Option<crate::model::Mode>,
}

impl<'de> serde::Deserialize<'de> for Dir {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        #[derive(serde::Deserialize)]
        #[serde(deny_unknown_fields)]
        struct RawDir {
            path: std::path::PathBuf,
            #[serde(default = "crate::model::default_platform_filter")]
            platform: crate::model::PlatformFilter,
            mode: Option<crate::model::Mode>,
        }

        let raw = RawDir::deserialize(deserializer)?;
        Dir::new(raw.path, raw.platform, raw.mode).map_err(serde::de::Error::custom)
    }
}

impl Dir {
    fn new(
        path: std::path::PathBuf,
        platform: crate::model::PlatformFilter,
        mode: Option<crate::model::Mode>,
    ) -> Result<Self, String> {
        crate::model::validations::path_string(&path, "dir path")?;
        Ok(Self {
            path,
            platform,
            mode,
        })
    }

    pub(crate) fn path(&self) -> &std::path::Path {
        &self.path
    }
    pub(crate) fn platform(&self) -> crate::model::PlatformFilter {
        self.platform
    }
    pub(crate) fn mode(&self) -> Option<crate::model::Mode> {
        self.mode
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::Mode;

    #[test]
    fn test_deserialize_without_mode() {
        let dir: Dir = toml::from_str(r#"path = "~/.ssh""#).unwrap();

        assert!(dir.mode().is_none());
        assert_eq!(dir.platform(), crate::model::PlatformFilter::Common);
    }

    #[test]
    fn test_deserialize_with_mode() {
        let dir: Dir = toml::from_str(
            r#"
path = "~/.ssh"
mode = "700"
"#,
        )
        .unwrap();

        assert_eq!(dir.path(), std::path::Path::new("~/.ssh"));
        assert_eq!(dir.mode().map(Mode::value), Some(0o700));
    }

    #[test]
    fn test_reject_shell_expansion() {
        let error = toml::from_str::<Dir>(r#"path = "$HOME/.ssh""#).unwrap_err();

        assert!(
            error
                .to_string()
                .contains("shell variable expansion is not supported")
        );
    }
}
