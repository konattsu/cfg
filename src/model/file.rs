#[derive(Debug)]
pub(crate) struct File {
    src: std::path::PathBuf,
    dst: std::path::PathBuf,
    platform: crate::model::PlatformFilter,
    mode: Option<crate::model::Mode>,
}

impl<'de> serde::Deserialize<'de> for File {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        #[derive(serde::Deserialize)]
        #[serde(deny_unknown_fields)]
        struct RawFile {
            src: std::path::PathBuf,
            dst: std::path::PathBuf,
            #[serde(default = "crate::model::default_platform_filter")]
            platform: crate::model::PlatformFilter,
            mode: Option<crate::model::Mode>,
        }

        let raw = RawFile::deserialize(deserializer)?;
        File::new(raw.src, raw.dst, raw.platform, raw.mode)
            .map_err(serde::de::Error::custom)
    }
}

impl File {
    fn new(
        src: std::path::PathBuf,
        dst: std::path::PathBuf,
        platform: crate::model::PlatformFilter,
        mode: Option<crate::model::Mode>,
    ) -> Result<Self, String> {
        crate::model::validations::module_relative_path(&src, "file src")?;
        crate::model::validations::path_string(&dst, "file dst")?;
        Ok(Self {
            src,
            dst,
            platform,
            mode,
        })
    }

    pub(crate) fn src(&self) -> &std::path::Path {
        &self.src
    }
    pub(crate) fn dst(&self) -> &std::path::Path {
        &self.dst
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

    #[test]
    fn test_deserialize_with_mode() {
        let file: File = toml::from_str(
            r#"
src = "files/config"
dst = "~/.config/moi/git/config"
mode = "644"
"#,
        )
        .unwrap();

        assert_eq!(file.src(), std::path::Path::new("files/config"));
        assert_eq!(file.dst(), std::path::Path::new("~/.config/moi/git/config"));
        assert_eq!(file.mode().map(crate::model::Mode::value), Some(0o644));
    }

    #[test]
    fn test_reject_absolute_src() {
        let error = toml::from_str::<File>(
            r#"
src = "/tmp/config"
dst = "~/.config/moi/git/config"
"#,
        )
        .unwrap_err();

        assert!(
            error
                .to_string()
                .contains("file src: must be module-relative")
        );
    }

    #[test]
    fn test_reject_parent_dir_src() {
        let error = toml::from_str::<File>(
            r#"
src = "../config"
dst = "~/.config/moi/git/config"
"#,
        )
        .unwrap_err();

        assert!(error.to_string().contains("must not contain .."));
    }

    #[test]
    fn test_reject_empty_dst() {
        let error = toml::from_str::<File>(
            r#"
src = "files/config"
dst = ""
"#,
        )
        .unwrap_err();

        assert!(error.to_string().contains("file dst"));
    }
}
