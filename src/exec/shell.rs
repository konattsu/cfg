pub(in crate::exec) fn run_bash(
    command: &str,
    cwd: &std::path::Path,
    env: &crate::exec::environment::ExecutionEnv,
) -> std::result::Result<(), crate::error::MoiError> {
    let status = run_bash_status(command, cwd, env)?;
    if !status.success() {
        return Err(crate::error::MoiError::CommandExit(
            status.code().unwrap_or(1),
        ));
    }
    Ok(())
}

pub(in crate::exec) fn run_bash_status(
    command: &str,
    cwd: &std::path::Path,
    env: &crate::exec::environment::ExecutionEnv,
) -> std::result::Result<std::process::ExitStatus, crate::error::MoiError> {
    let mut process = std::process::Command::new("bash");
    process.arg("-c").arg(command).current_dir(cwd);
    env.apply_to(&mut process);

    let status = process
        .status()
        .map_err(|source| crate::error::MoiError::io(cwd, source))?;
    Ok(status)
}

pub(in crate::exec) fn which(
    command: &str,
    env: &crate::exec::environment::ExecutionEnv,
) -> bool {
    std::env::split_paths(env.path()).any(|dir| {
        let candidate = dir.join(command);
        candidate.is_file() && is_executable(&candidate)
    })
}

fn is_executable(path: &std::path::Path) -> bool {
    use std::os::unix::fs::PermissionsExt;

    std::fs::metadata(path)
        .map(|metadata| metadata.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}
