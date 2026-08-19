pub fn run(cli: crate::cli::Cli) -> std::result::Result<(), crate::error::MoiError> {
    let settings =
        crate::config::Settings::resolve(crate::config::SettingsOverrides {
            environment: cli.settings.environment.as_deref(),
            folder_name: cli.settings.folder_name.as_deref(),
            source: cli.settings.source.as_deref(),
        })?;
    settings.write_if_missing()?;
    let repo = RepoCheckout::prepare(settings.source())?;
    let modules_dir = repo
        .path()
        .join(settings.folder_name())
        .join(settings.environment())
        .join("modules");
    let modules = crate::model::modules::load(&modules_dir)?;
    let ordered =
        crate::model::modules::resolve(&modules, &cli.command.run_args().modules)?;
    let platform = resolve_platform(&cli.command)?;
    let show_followups = should_show_followups(cli.command.run_args());
    match &cli.command {
        crate::cli::Command::Plan(_) => print_plan(&ordered, platform, show_followups),
        crate::cli::Command::Apply(args) => apply(
            &ordered,
            repo.path(),
            platform,
            show_followups,
            args.ignore_unless,
        ),
    }
}

struct RepoCheckout {
    path: std::path::PathBuf,
    _tempdir: Option<tempfile::TempDir>,
}

impl RepoCheckout {
    fn prepare(source: &str) -> std::result::Result<Self, crate::error::MoiError> {
        if let Some(path) = source.strip_prefix("file://") {
            return Ok(Self {
                path: std::path::PathBuf::from(path),
                _tempdir: None,
            });
        }
        let tempdir = tempfile::Builder::new()
            .prefix("moi-")
            .tempdir()
            .map_err(|source| crate::error::MoiError::IoMessage(source.to_string()))?;
        let branch = std::env::var("MOI_BRANCH").unwrap_or_else(|_| "main".to_string());
        let status = std::process::Command::new("git")
            .arg("clone")
            .arg("--depth")
            .arg("1")
            .arg("--branch")
            .arg(&branch)
            .arg(source)
            .arg(tempdir.path())
            .status()
            .map_err(|source| crate::error::MoiError::IoMessage(source.to_string()))?;
        if !status.success() {
            return Err(crate::error::MoiError::CommandExit(
                status.code().unwrap_or(1),
            ));
        }
        Ok(Self {
            path: tempdir.path().to_path_buf(),
            _tempdir: Some(tempdir),
        })
    }

    fn path(&self) -> &std::path::Path {
        &self.path
    }
}

fn resolve_platform(
    command: &crate::cli::Command,
) -> std::result::Result<crate::platform::Platform, crate::error::MoiError> {
    match command.run_args().platform {
        crate::cli::PlatformArg::Auto => crate::platform::detect(),
        crate::cli::PlatformArg::Debian => Ok(crate::platform::Platform::Debian),
        crate::cli::PlatformArg::Arch => Ok(crate::platform::Platform::Arch),
    }
}

fn should_show_followups(args: &crate::cli::RunArgs) -> bool {
    if let Some(value) = args.followups_override() {
        return value;
    }
    std::env::var("MOI_FIRST_INSTALL").ok().as_deref() == Some("1")
}

fn collect_packages(
    modules: &[&crate::model::Module],
    platform: crate::platform::Platform,
) -> Vec<String> {
    let mut seen = std::collections::BTreeSet::new();
    let mut packages = Vec::new();
    for module in modules {
        for package in module.packages().for_platform(platform) {
            if seen.insert(package.clone()) {
                packages.push(package.clone());
            }
        }
    }
    packages
}

fn print_plan(
    modules: &[&crate::model::Module],
    platform: crate::platform::Platform,
    show_followups: bool,
) -> std::result::Result<(), crate::error::MoiError> {
    let packages = collect_packages(modules, platform);
    crate::output!("Modules:");
    for module in modules {
        crate::output!("  - {}", module.name());
    }
    crate::output!();
    crate::output!("Platform: {}", platform.name());
    crate::output!();
    crate::output!("{} packages:", platform.package_key());
    if packages.is_empty() {
        crate::output!("  (none)");
    } else {
        for package in &packages {
            crate::output!("  - {package}");
        }
    }
    crate::output!();
    crate::output!("Operations:");
    let mut env = crate::exec::environment::ExecutionEnv::new();
    for module in modules {
        crate::output!("[{}]", module.name());
        env.apply_module_env(module)?;
        plan_module_operations(module, platform)?;
    }
    if show_followups {
        print_followups(modules);
    }
    Ok(())
}

fn apply(
    modules: &[&crate::model::Module],
    repo_root: &std::path::Path,
    platform: crate::platform::Platform,
    show_followups: bool,
    ignore_unless: bool,
) -> std::result::Result<(), crate::error::MoiError> {
    let mut env = crate::exec::environment::ExecutionEnv::new();
    let packages = collect_packages(modules, platform);
    crate::exec::package::install(&packages, platform, repo_root, &env)?;
    for module in modules {
        crate::output!("==> {}", module.name());
        env.apply_module_env(module)?;
        apply_module_operations(module, platform, &mut env, ignore_unless)?;
    }
    if show_followups {
        print_followups(modules);
    }
    Ok(())
}

fn plan_module_operations(
    module: &crate::model::Module,
    platform: crate::platform::Platform,
) -> std::result::Result<(), crate::error::MoiError> {
    for dir in module.dirs() {
        if dir.platform().matches(platform) {
            crate::exec::dir::plan(dir)?;
        }
    }
    for file in module.files() {
        if file.platform().matches(platform) {
            crate::exec::file::plan(module, file)?;
        }
    }
    for block in module.blocks() {
        if block.platform().matches(platform) {
            crate::exec::block::plan(module, block)?;
        }
    }
    for (index, command) in module.commands().iter().enumerate() {
        if command.platform().matches(platform) {
            crate::exec::command::plan(command, index + 1, false);
        }
    }
    Ok(())
}

fn apply_module_operations(
    module: &crate::model::Module,
    platform: crate::platform::Platform,
    env: &mut crate::exec::environment::ExecutionEnv,
    ignore_unless: bool,
) -> std::result::Result<(), crate::error::MoiError> {
    for dir in module.dirs() {
        if dir.platform().matches(platform) {
            crate::exec::dir::apply(dir)?;
        }
    }
    for file in module.files() {
        if file.platform().matches(platform) {
            crate::exec::file::apply(module, file)?;
        }
    }
    for block in module.blocks() {
        if block.platform().matches(platform) {
            crate::exec::block::apply(module, block)?;
        }
    }
    for (index, command) in module.commands().iter().enumerate() {
        if command.platform().matches(platform) {
            crate::exec::command::apply(
                module,
                command,
                index + 1,
                env,
                ignore_unless,
            )?;
        }
    }
    Ok(())
}

fn print_followups(modules: &[&crate::model::Module]) {
    let followups = modules
        .iter()
        .flat_map(|module| module.followups())
        .collect::<Vec<_>>();
    if followups.is_empty() {
        return;
    }
    crate::output!();
    crate::output!("Follow-ups:");
    for followup in followups {
        crate::output!("  - {followup}");
    }
}
