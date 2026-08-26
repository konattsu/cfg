pub(crate) struct ExecutionEnv {
    path: String,
}

impl ExecutionEnv {
    pub(crate) fn new() -> Self {
        Self {
            path: std::env::var("PATH").unwrap_or_default(),
        }
    }

    pub(crate) fn apply_module_env(
        &mut self,
        module: &crate::model::Module,
    ) -> Result<(), crate::error::MoiError> {
        let paths = module.env().path_prepend();
        if paths.is_empty() {
            return Ok(());
        }

        let mut values: Vec<std::path::PathBuf> = paths
            .iter()
            .map(|path| crate::path::expand_home(path))
            .collect::<Result<_, crate::error::MoiError>>()?;
        values.extend(std::env::split_paths(&self.path));
        self.path = std::env::join_paths(values)
            .map_err(|error| crate::error::MoiError::config(error.to_string()))?
            .to_string_lossy()
            .to_string();
        Ok(())
    }

    pub(in crate::exec) fn set_path(&mut self, path: String) {
        self.path = path;
    }

    pub(in crate::exec) fn path(&self) -> &str {
        &self.path
    }

    pub(in crate::exec) fn apply_to(&self, command: &mut std::process::Command) {
        command.env("PATH", &self.path);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_path_prepend_preserves_existing_path_segments() {
        let module: crate::model::Module = toml::from_str(
            r#"
name = "test"

[env]
path_prepend = ["/opt/bin"]
"#,
        )
        .unwrap();
        let mut env = ExecutionEnv {
            path: "/usr/local/bin:/usr/bin".to_string(),
        };

        env.apply_module_env(&module).unwrap();

        let paths = std::env::split_paths(env.path()).collect::<Vec<_>>();
        assert_eq!(
            paths,
            [
                std::path::PathBuf::from("/opt/bin"),
                std::path::PathBuf::from("/usr/local/bin"),
                std::path::PathBuf::from("/usr/bin"),
            ]
        );
    }
}
