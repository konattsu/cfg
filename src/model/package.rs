#[derive(Debug, Default)]
pub(crate) struct Packages {
    apt: Vec<String>,
    pacman: Vec<String>,
}

impl<'de> serde::Deserialize<'de> for Packages {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        #[derive(serde::Deserialize)]
        #[serde(deny_unknown_fields)]
        struct RawPackages {
            #[serde(default)]
            apt: Vec<String>,
            #[serde(default)]
            pacman: Vec<String>,
        }

        let raw = RawPackages::deserialize(deserializer)?;
        Packages::new(raw.apt, raw.pacman).map_err(serde::de::Error::custom)
    }
}

impl Packages {
    fn new(apt: Vec<String>, pacman: Vec<String>) -> Result<Self, String> {
        validate_package_names(&apt, "packages.apt")?;
        validate_package_names(&pacman, "packages.pacman")?;
        Ok(Self { apt, pacman })
    }

    pub(crate) fn for_platform(
        &self,
        platform: crate::platform::Platform,
    ) -> &[String] {
        match platform {
            crate::platform::Platform::Debian => &self.apt,
            crate::platform::Platform::Arch => &self.pacman,
        }
    }
}

fn validate_package_names(values: &[String], where_: &str) -> Result<(), String> {
    for (index, value) in values.iter().enumerate() {
        crate::model::validations::non_empty_string(
            value,
            &format!("{where_}[{index}]"),
        )?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_reject_empty_package_name() {
        let error = toml::from_str::<Packages>(
            r#"
apt = [""]
"#,
        )
        .unwrap_err();

        assert!(error.to_string().contains("packages.apt[0]"));
    }
}
