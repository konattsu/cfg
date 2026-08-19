pub(crate) fn install(
    packages: &[String],
    platform: crate::platform::Platform,
    repo_root: &std::path::Path,
    env: &crate::exec::environment::ExecutionEnv,
    upgrade: bool,
) -> std::result::Result<(), crate::error::MoiError> {
    if packages.is_empty() {
        return Ok(());
    }
    let quoted = packages
        .iter()
        .map(|package| crate::exec::path::shell_quote(package))
        .collect::<Vec<_>>()
        .join(" ");
    match platform {
        crate::platform::Platform::Debian => {
            crate::output!("apt update");
            crate::exec::shell::run_bash("sudo apt update", repo_root, env)?;
            if upgrade {
                crate::output!("apt upgrade");
                crate::exec::shell::run_bash("sudo apt upgrade -y", repo_root, env)?;
            }
            crate::output!("apt install {quoted}");
            crate::exec::shell::run_bash(
                &format!("sudo apt install -y {quoted}"),
                repo_root,
                env,
            )?;
        }
        crate::platform::Platform::Arch => {
            let command = pacman_install_command(&quoted, upgrade);
            crate::output!("{}", command.display);
            crate::exec::shell::run_bash(&command.run, repo_root, env)?;
        }
    }
    Ok(())
}

struct PackageCommand {
    run: String,
    display: String,
}

impl PackageCommand {
    fn new(run: String) -> Self {
        let display = run.strip_prefix("sudo ").unwrap_or(&run).to_string();
        Self { run, display }
    }
}

fn pacman_install_command(packages: &str, upgrade: bool) -> PackageCommand {
    let flags = if upgrade { "-Syu" } else { "-S" };
    PackageCommand::new(format!(
        "sudo pacman {flags} --needed --noconfirm {packages}"
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pacman_install_command_without_upgrade() {
        let command = pacman_install_command("'git'", false);

        assert_eq!(command.run, "sudo pacman -S --needed --noconfirm 'git'");
        assert_eq!(command.display, "pacman -S --needed --noconfirm 'git'");
    }

    #[test]
    fn test_pacman_install_command_with_upgrade() {
        let command = pacman_install_command("'git'", true);

        assert_eq!(command.run, "sudo pacman -Syu --needed --noconfirm 'git'");
        assert_eq!(command.display, "pacman -Syu --needed --noconfirm 'git'");
    }
}
