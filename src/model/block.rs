#[derive(Debug)]
pub(crate) struct Block {
    src: std::path::PathBuf,
    dst: std::path::PathBuf,
    marker: String,
    platform: crate::model::PlatformFilter,
}

impl<'de> serde::Deserialize<'de> for Block {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        #[derive(serde::Deserialize)]
        #[serde(deny_unknown_fields)]
        struct RawBlock {
            src: std::path::PathBuf,
            dst: std::path::PathBuf,
            marker: String,
            #[serde(default = "crate::model::default_platform_filter")]
            platform: crate::model::PlatformFilter,
        }

        let raw = RawBlock::deserialize(deserializer)?;
        Block::new(raw.src, raw.dst, raw.marker, raw.platform)
            .map_err(serde::de::Error::custom)
    }
}

impl Block {
    const COMMENT_PREFIX: &'static str = "#";

    fn new(
        src: std::path::PathBuf,
        dst: std::path::PathBuf,
        marker: String,
        platform: crate::model::PlatformFilter,
    ) -> Result<Self, String> {
        crate::model::validations::module_relative_path(&src, "block src")?;
        crate::model::validations::path_string(&dst, "block dst")?;
        if marker.is_empty() || marker.contains(">>>") || marker.contains('\n') {
            return Err(
                "block marker must not be empty and must not contain >>> or newline"
                    .to_string(),
            );
        }
        Ok(Self {
            src,
            dst,
            marker,
            platform,
        })
    }

    pub(crate) fn src(&self) -> &std::path::Path {
        &self.src
    }
    pub(crate) fn dst(&self) -> &std::path::Path {
        &self.dst
    }
    pub(crate) fn marker(&self) -> &str {
        &self.marker
    }
    pub(crate) fn platform(&self) -> crate::model::PlatformFilter {
        self.platform
    }

    pub(crate) fn start_line(marker: &str) -> String {
        format!("{} >>> {marker} >>>", Self::COMMENT_PREFIX)
    }

    pub(crate) fn end_line(marker: &str) -> String {
        format!("{} <<< {marker} <<<", Self::COMMENT_PREFIX)
    }

    pub(crate) fn text(marker: &str, content: &str) -> String {
        let mut body = content.to_string();
        if !body.is_empty() && !body.ends_with('\n') {
            body.push('\n');
        }
        format!(
            "{}\n{body}{}\n",
            Self::start_line(marker),
            Self::end_line(marker)
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_reject_parent_dir_src() {
        let error = toml::from_str::<Block>(
            r#"
src = "../keychain.sh"
dst = "~/.zshrc"
marker = "moi:keychain"
"#,
        )
        .unwrap_err();

        assert!(error.to_string().contains("must not contain .."));
    }
}
