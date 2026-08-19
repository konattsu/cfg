#[derive(Debug, thiserror::Error)]
pub enum MoiError {
    #[error("{0}")]
    Config(String),
    #[error("{path}: {source}")]
    Io {
        path: std::path::PathBuf,
        source: std::io::Error,
    },
    #[error("{0}")]
    IoMessage(String),
    #[error("command failed with exit code {0}")]
    CommandExit(i32),
    #[error("{path}: invalid TOML: {source}")]
    Toml {
        path: std::path::PathBuf,
        source: toml::de::Error,
    },
}

impl MoiError {
    pub(crate) fn config(message: impl Into<String>) -> Self {
        Self::Config(message.into())
    }

    pub(crate) fn io(
        path: impl Into<std::path::PathBuf>,
        source: std::io::Error,
    ) -> Self {
        Self::Io {
            path: path.into(),
            source,
        }
    }
}
