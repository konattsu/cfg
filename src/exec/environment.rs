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
    ) -> std::result::Result<(), crate::error::MoiError> {
        let paths = module.env().path_prepend();
        if paths.is_empty() {
            return Ok(());
        }

        let mut values = paths
            .iter()
            .map(|path| {
                crate::path::expand_home(path)
                    .map(|path| path.to_string_lossy().to_string())
            })
            .collect::<std::result::Result<Vec<_>, crate::error::MoiError>>()?;
        values.push(self.path.clone());
        self.path = std::env::join_paths(values.iter().map(std::path::Path::new))
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
