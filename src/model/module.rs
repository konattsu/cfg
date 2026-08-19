#[derive(Debug)]
pub(crate) struct Module {
    name: ModuleName,
    path: std::path::PathBuf,
    depends_on: Vec<ModuleName>,
    followups: Vec<String>,
    packages: crate::model::Packages,
    dirs: Vec<crate::model::Dir>,
    files: Vec<crate::model::File>,
    blocks: Vec<crate::model::Block>,
    commands: Vec<crate::model::Command>,
    env: crate::model::Env,
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub(crate) struct ModuleName(String);

#[derive(serde::Deserialize)]
#[serde(deny_unknown_fields)]
struct RawModule {
    name: ModuleName,
    #[serde(default)]
    depends_on: Vec<ModuleName>,
    #[serde(default)]
    followups: Vec<String>,
    #[serde(default)]
    packages: crate::model::Packages,
    #[serde(default)]
    dirs: Vec<crate::model::Dir>,
    #[serde(default)]
    files: Vec<crate::model::File>,
    #[serde(default)]
    blocks: Vec<crate::model::Block>,
    #[serde(default)]
    commands: Vec<crate::model::Command>,
    #[serde(default)]
    env: crate::model::Env,
}

impl Module {
    pub(crate) fn name(&self) -> &ModuleName {
        &self.name
    }
    pub(crate) fn path(&self) -> &std::path::Path {
        &self.path
    }
    pub(crate) fn depends_on(&self) -> &[ModuleName] {
        &self.depends_on
    }
    pub(crate) fn followups(&self) -> &[String] {
        &self.followups
    }
    pub(crate) fn packages(&self) -> &crate::model::Packages {
        &self.packages
    }
    pub(crate) fn dirs(&self) -> &[crate::model::Dir] {
        &self.dirs
    }
    pub(crate) fn files(&self) -> &[crate::model::File] {
        &self.files
    }
    pub(crate) fn blocks(&self) -> &[crate::model::Block] {
        &self.blocks
    }
    pub(crate) fn commands(&self) -> &[crate::model::Command] {
        &self.commands
    }
    pub(crate) fn env(&self) -> &crate::model::Env {
        &self.env
    }
    pub(in crate::model) fn set_path(&mut self, path: std::path::PathBuf) {
        self.path = path;
    }
}

impl<'de> serde::Deserialize<'de> for Module {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let raw = RawModule::deserialize(deserializer)?;
        Module::from_raw(raw).map_err(serde::de::Error::custom)
    }
}

impl Module {
    fn from_raw(raw: RawModule) -> Result<Self, String> {
        for (index, followup) in raw.followups.iter().enumerate() {
            crate::model::validations::non_empty_string(
                followup,
                &format!("followups[{index}]"),
            )?;
        }
        Ok(Self {
            name: raw.name,
            path: std::path::PathBuf::new(),
            depends_on: raw.depends_on,
            followups: raw.followups,
            packages: raw.packages,
            dirs: raw.dirs,
            files: raw.files,
            blocks: raw.blocks,
            commands: raw.commands,
            env: raw.env,
        })
    }
}

impl ModuleName {
    pub(crate) fn as_str(&self) -> &str {
        &self.0
    }
}

impl<'de> serde::Deserialize<'de> for ModuleName {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let raw = <String as serde::Deserialize>::deserialize(deserializer)?;
        ModuleName::new(raw).map_err(serde::de::Error::custom)
    }
}

impl ModuleName {
    fn new(value: String) -> Result<Self, String> {
        crate::model::validations::non_empty_string(&value, "module name")?;
        Ok(Self(value))
    }
}

impl std::fmt::Display for ModuleName {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_reject_empty_module_name() {
        let error = toml::from_str::<Module>(r#"name = """#).unwrap_err();

        assert!(error.to_string().contains("module name"));
    }

    #[test]
    fn test_reject_empty_followup() {
        let error = toml::from_str::<Module>(
            r#"
name = "core"
followups = [""]
"#,
        )
        .unwrap_err();

        assert!(error.to_string().contains("followups[0]"));
    }
}
