#[derive(Debug, clap::Parser)]
#[command(name = "moi")]
#[command(about = "moi module planner/applicator")]
pub struct Cli {
    #[command(flatten)]
    pub(crate) settings: SettingsArgs,
    #[command(flatten)]
    pub(crate) output: OutputArgs,
    #[command(subcommand)]
    pub(crate) command: Command,
}

#[derive(Debug, clap::Args)]
pub(crate) struct SettingsArgs {
    #[arg(short = 'e', long, global = true, help = "Target environment name")]
    pub(crate) environment: Option<String>,
    #[arg(
        long = "folder-name",
        global = true,
        help = "Repository-relative environments folder"
    )]
    pub(crate) folder_name: Option<String>,
    #[arg(
        long,
        global = true,
        help = "Repository source URL or file:// local repository path"
    )]
    pub(crate) source: Option<String>,
}

#[derive(Debug, clap::Args)]
pub(crate) struct OutputArgs {
    #[arg(
        long,
        global = true,
        conflicts_with = "verbose",
        help = "Suppress normal output"
    )]
    pub(crate) quiet: bool,
    #[arg(
        short,
        long,
        action = clap::ArgAction::Count,
        global = true,
        help = "Increase diagnostic output"
    )]
    pub(crate) verbose: u8,
}

#[derive(Debug, clap::Subcommand)]
pub(crate) enum Command {
    /// Show planned operations without changing files.
    Plan(RunArgs),
    /// Apply planned operations.
    Apply(ApplyArgs),
    /// Print a shell command that installs moi and runs plan/apply.
    #[command(name = "install-command")]
    Install(InstallCommandArgs),
}

#[derive(Debug, clap::Args)]
pub(crate) struct RunArgs {
    #[arg(long, default_value_t = PlatformArg::Auto, help = "Target platform")]
    pub(crate) platform: PlatformArg,
    #[arg(long, conflicts_with = "no_followups", help = "Show follow-up tasks")]
    show_followups: bool,
    #[arg(long, conflicts_with = "show_followups", help = "Hide follow-up tasks")]
    no_followups: bool,
    #[arg(help = "Module names to process")]
    pub(crate) modules: Vec<String>,
}

#[derive(Debug, clap::Args)]
pub(crate) struct ApplyArgs {
    #[command(flatten)]
    pub(crate) run: RunArgs,
    #[arg(long, help = "Run commands without evaluating their unless guards")]
    pub(crate) ignore_unless: bool,
    #[arg(
        long,
        help = "Upgrade system packages before installing missing packages"
    )]
    pub(crate) upgrade_packages: bool,
}

#[derive(Debug, clap::Args)]
pub(crate) struct InstallCommandArgs {
    #[arg(
        long,
        help = "Base URL or local directory containing the install script"
    )]
    pub(crate) install_source: Option<String>,
    #[arg(long, help = "Install script path relative to --install-source")]
    pub(crate) install_script: Option<String>,
    #[arg(
        value_enum,
        default_value_t = InstallOperationArg::Apply,
        help = "Operation passed to the installed moi binary"
    )]
    pub(crate) operation: InstallOperationArg,
    #[arg(
        trailing_var_arg = true,
        allow_hyphen_values = true,
        help = "Arguments passed after the operation"
    )]
    pub(crate) args: Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, clap::ValueEnum)]
pub(crate) enum PlatformArg {
    Auto,
    Debian,
    Arch,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, clap::ValueEnum)]
pub(crate) enum InstallOperationArg {
    Plan,
    Apply,
}

impl Cli {
    pub fn stdout_settings(&self) -> crate::util::tracing::StdoutSettings {
        crate::util::tracing::StdoutSettings {
            quiet: self.output.quiet,
            verbose: self.output.verbose,
        }
    }
}

impl RunArgs {
    pub(crate) fn followups_override(&self) -> Option<bool> {
        if self.show_followups {
            return Some(true);
        }
        if self.no_followups {
            return Some(false);
        }
        None
    }
}

impl std::fmt::Display for PlatformArg {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter.write_str(match self {
            PlatformArg::Auto => "auto",
            PlatformArg::Debian => "debian",
            PlatformArg::Arch => "arch",
        })
    }
}

impl std::fmt::Display for InstallOperationArg {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter.write_str(match self {
            InstallOperationArg::Plan => "plan",
            InstallOperationArg::Apply => "apply",
        })
    }
}

#[cfg(test)]
mod tests {
    use clap::Parser;

    #[test]
    fn test_parse_settings_before_command() {
        let cli = super::Cli::parse_from(["moi", "--environment", "host", "plan"]);

        assert_eq!(cli.settings.environment.as_deref(), Some("host"));
    }

    #[test]
    fn test_parse_environment_short_flag() {
        let cli = super::Cli::parse_from(["moi", "-e", "host", "plan"]);

        assert_eq!(cli.settings.environment.as_deref(), Some("host"));
    }

    #[test]
    fn test_parse_global_settings_after_command() {
        let cli = super::Cli::parse_from(["moi", "plan", "--environment", "host"]);

        assert_eq!(cli.settings.environment.as_deref(), Some("host"));
    }

    #[test]
    fn test_reject_conflicting_followup_flags() {
        let error = super::Cli::try_parse_from([
            "moi",
            "plan",
            "--show-followups",
            "--no-followups",
        ])
        .unwrap_err();

        assert_eq!(error.kind(), clap::error::ErrorKind::ArgumentConflict);
    }

    #[test]
    fn test_reject_unknown_platform() {
        let error = super::Cli::try_parse_from(["moi", "plan", "--platform", "fedora"])
            .unwrap_err();

        assert_eq!(error.kind(), clap::error::ErrorKind::InvalidValue);
    }

    #[test]
    fn test_parse_global_output_flags_after_command() {
        let cli = super::Cli::parse_from(["moi", "plan", "--quiet"]);

        assert!(cli.output.quiet);
    }

    #[test]
    fn test_count_verbose_flags() {
        let cli = super::Cli::parse_from(["moi", "-vv", "plan"]);

        assert_eq!(cli.output.verbose, 2);
    }

    #[test]
    fn test_reject_quiet_verbose_conflict() {
        let error =
            super::Cli::try_parse_from(["moi", "--quiet", "-v", "plan"]).unwrap_err();

        assert_eq!(error.kind(), clap::error::ErrorKind::ArgumentConflict);
    }

    #[test]
    fn test_parse_upgrade_packages() {
        let cli = super::Cli::parse_from(["moi", "apply", "--upgrade-packages"]);
        let super::Command::Apply(args) = cli.command else {
            panic!("expected apply command");
        };

        assert!(args.upgrade_packages);
    }

    #[test]
    fn test_parse_install_command_defaults_to_apply() {
        let cli = super::Cli::parse_from([
            "moi",
            "install-command",
            "--environment",
            "devcontainer",
        ]);
        let super::Command::Install(args) = cli.command else {
            panic!("expected install-command");
        };

        assert_eq!(cli.settings.environment.as_deref(), Some("devcontainer"));
        assert_eq!(args.operation, super::InstallOperationArg::Apply);
        assert_eq!(args.install_script, None);
    }

    #[test]
    fn test_parse_install_command_plan_args() {
        let cli = super::Cli::parse_from([
            "moi",
            "install-command",
            "--environment",
            "devcontainer",
            "plan",
            "--platform",
            "arch",
            "nvim",
        ]);
        let super::Command::Install(args) = cli.command else {
            panic!("expected install-command");
        };

        assert_eq!(args.operation, super::InstallOperationArg::Plan);
        assert_eq!(args.args, ["--platform", "arch", "nvim"]);
    }

    #[test]
    fn test_parse_install_command_apply_args() {
        let cli = super::Cli::parse_from([
            "moi",
            "install-command",
            "--environment",
            "devcontainer",
            "apply",
            "--upgrade-packages",
        ]);
        let super::Command::Install(args) = cli.command else {
            panic!("expected install-command");
        };

        assert_eq!(args.operation, super::InstallOperationArg::Apply);
        assert_eq!(args.args, ["--upgrade-packages"]);
    }
}
