mod defaults {
    pub(super) const FOLDER_NAME: &str = "environments";
    pub(super) const SOURCE: &str = "https://github.com/konattsu/moi.git";
    pub(super) const CONFIG_DIR: &str = ".config/moi";
    pub(super) const CONFIG_FILE: &str = "config.toml";
}

#[derive(Debug)]
pub(crate) struct Settings {
    environment: String,
    folder_name: String,
    source: String,
}

#[derive(Debug, Clone, Copy)]
pub(crate) struct SettingsOverrides<'a> {
    pub(crate) environment: Option<&'a str>,
    pub(crate) folder_name: Option<&'a str>,
    pub(crate) source: Option<&'a str>,
}

#[derive(Debug, Default, serde::Deserialize)]
#[serde(deny_unknown_fields)]
struct ConfigFile {
    default_environment: Option<String>,
    default_folder_name: Option<String>,
    default_source: Option<String>,
}

#[derive(Debug)]
struct EnvOverrides {
    environment: Option<String>,
    folder_name: Option<String>,
    source: Option<String>,
}

#[derive(Debug, Clone, Copy)]
struct SettingSources<'a> {
    cli: Option<&'a str>,
    env: Option<&'a str>,
    file: Option<&'a str>,
}

impl Settings {
    pub(crate) fn resolve(
        cli: SettingsOverrides<'_>,
    ) -> std::result::Result<Self, crate::error::MoiError> {
        let config_path = config_path()?;
        let config = read_config_file(&config_path)?;
        let env = EnvOverrides::read();
        let environment = resolve_setting(
            SettingSources {
                cli: cli.environment,
                env: env.environment.as_deref(),
                file: config.default_environment.as_deref(),
            },
            "MOI_ENVIRONMENT",
            "environment",
            None,
            &config_path,
        )?;
        let folder_name = validate_folder_name(&resolve_setting(
            SettingSources {
                cli: cli.folder_name,
                env: env.folder_name.as_deref(),
                file: config.default_folder_name.as_deref(),
            },
            "MOI_FOLDER_NAME",
            "folder_name",
            Some(defaults::FOLDER_NAME),
            &config_path,
        )?)?;
        let source = validate_source(&resolve_setting(
            SettingSources {
                cli: cli.source,
                env: env.source.as_deref(),
                file: config.default_source.as_deref(),
            },
            "MOI_SOURCE",
            "source",
            Some(defaults::SOURCE),
            &config_path,
        )?)?;
        Ok(Self {
            environment,
            folder_name,
            source,
        })
    }

    pub(crate) fn environment(&self) -> &str {
        &self.environment
    }
    pub(crate) fn folder_name(&self) -> &str {
        &self.folder_name
    }
    pub(crate) fn source(&self) -> &str {
        &self.source
    }

    pub(crate) fn write_if_missing(
        &self,
    ) -> std::result::Result<(), crate::error::MoiError> {
        let path = config_path()?;
        if path.exists() {
            return Ok(());
        }
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)
                .map_err(|source| crate::error::MoiError::io(parent, source))?;
        }
        let content = format!(
            "default_environment = \"{}\"\ndefault_folder_name = \"{}\"\ndefault_source = \"{}\"\n",
            escape_basic_string(&self.environment),
            escape_basic_string(&self.folder_name),
            escape_basic_string(&self.source)
        );
        std::fs::write(&path, content)
            .map_err(|source| crate::error::MoiError::io(path, source))
    }
}

impl EnvOverrides {
    fn read() -> Self {
        Self {
            environment: read_env("MOI_ENVIRONMENT"),
            folder_name: read_env("MOI_FOLDER_NAME"),
            source: read_env("MOI_SOURCE"),
        }
    }
}

pub(crate) fn config_path()
-> std::result::Result<std::path::PathBuf, crate::error::MoiError> {
    Ok(crate::path::home_dir()?
        .join(defaults::CONFIG_DIR)
        .join(defaults::CONFIG_FILE))
}

fn read_config_file(
    path: &std::path::Path,
) -> std::result::Result<ConfigFile, crate::error::MoiError> {
    if !path.exists() {
        return Ok(ConfigFile::default());
    }
    let content = std::fs::read_to_string(path)
        .map_err(|source| crate::error::MoiError::io(path, source))?;
    let config: ConfigFile =
        toml::from_str(&content).map_err(|source| crate::error::MoiError::Toml {
            path: path.to_path_buf(),
            source,
        })?;
    validate_optional_string(&config.default_environment, path, "default_environment")?;
    validate_optional_string(&config.default_folder_name, path, "default_folder_name")?;
    validate_optional_string(&config.default_source, path, "default_source")?;
    Ok(config)
}

fn validate_optional_string(
    value: &Option<String>,
    path: &std::path::Path,
    key: &str,
) -> std::result::Result<(), crate::error::MoiError> {
    if value.as_deref() == Some("") {
        return Err(crate::error::MoiError::config(format!(
            "{}: {key} must be a non-empty string",
            path.display()
        )));
    }
    Ok(())
}

fn read_env(name: &str) -> Option<String> {
    std::env::var(name).ok().filter(|value| !value.is_empty())
}

fn resolve_setting(
    sources: SettingSources<'_>,
    env_name: &str,
    display_name: &str,
    default: Option<&str>,
    config_path: &std::path::Path,
) -> std::result::Result<String, crate::error::MoiError> {
    let value = sources
        .cli
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .or_else(|| sources.env.map(str::to_string))
        .or_else(|| {
            sources
                .file
                .filter(|val| !val.is_empty())
                .map(str::to_string)
        })
        .or_else(|| default.map(str::to_string));
    value.ok_or_else(|| {
        crate::error::MoiError::config(format!(
            "missing required setting: {display_name} (use --{} or {env_name} or {})",
            display_name.replace('_', "-"),
            config_path.display()
        ))
    })
}

fn validate_source(value: &str) -> std::result::Result<String, crate::error::MoiError> {
    if value.starts_with("https://") || value.starts_with("file:///") {
        return Ok(value.to_string());
    }
    Err(crate::error::MoiError::config(
        "source must start with \"https://\" or \"file:///\"",
    ))
}

fn validate_folder_name(
    value: &str,
) -> std::result::Result<String, crate::error::MoiError> {
    let path = std::path::Path::new(value);
    if path.is_absolute() || path.components().any(|part| part.as_os_str() == "..") {
        return Err(crate::error::MoiError::config(
            "folder_name must be repository-relative and must not contain ..",
        ));
    }
    Ok(value.trim_matches('/').to_string())
}

fn escape_basic_string(value: &str) -> String {
    value.replace('\\', "\\\\").replace('"', "\\\"")
}
