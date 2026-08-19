pub(crate) fn install(
    packages: &[String],
    platform: crate::platform::Platform,
    repo_root: &std::path::Path,
    env: &crate::exec::environment::ExecutionEnv,
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
            crate::output!("apt upgrade");
            crate::exec::shell::run_bash("sudo apt upgrade -y", repo_root, env)?;
            crate::output!("apt install {quoted}");
            crate::exec::shell::run_bash(
                &format!("sudo apt install -y {quoted}"),
                repo_root,
                env,
            )?;
        }
        crate::platform::Platform::Arch => {
            crate::output!("pacman -Syu --needed --noconfirm {quoted}");
            crate::exec::shell::run_bash(
                &format!("sudo pacman -Syu --needed --noconfirm {quoted}"),
                repo_root,
                env,
            )?;
        }
    }
    Ok(())
}
