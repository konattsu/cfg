pub(crate) fn run(
    args: &crate::cli::UpgradeArgs,
) -> std::result::Result<(), crate::error::MoiError> {
    let current = semver::Version::parse(env!("CARGO_PKG_VERSION"))
        .map_err(|source| crate::error::MoiError::config(source.to_string()))?;
    let latest = latest_version()?;

    if current > latest {
        crate::output!("moi v{current} is newer than the latest release (v{latest}).");
        return Ok(());
    }
    if current == latest && !args.force {
        crate::output!("moi v{current} is already up to date.");
        return Ok(());
    }

    if current == latest {
        crate::output!("Reinstalling moi v{current}...");
    } else {
        crate::output!("Upgrading moi v{current} to v{latest}...");
    }
    install_latest()?;
    crate::output!("Successfully upgraded moi to v{latest}.");
    Ok(())
}

fn latest_version() -> std::result::Result<semver::Version, crate::error::MoiError> {
    let repository = std::env::var("MOI_GITHUB_REPOSITORY")
        .unwrap_or_else(|_| "konattsu/moi".to_string());
    let url = std::env::var("MOI_LATEST_RELEASE_URL")
        .unwrap_or_else(|_| format!("https://github.com/{repository}/releases/latest"));
    let output = std::process::Command::new("curl")
        .args(["-fsSL", "-o", "/dev/null", "-w", "%{url_effective}", &url])
        .output()
        .map_err(|source| crate::error::MoiError::io("curl", source))?;
    if !output.status.success() {
        return Err(crate::error::MoiError::CommandExit(
            output.status.code().unwrap_or(1),
        ));
    }
    let effective_url = std::str::from_utf8(&output.stdout)
        .map_err(|source| crate::error::MoiError::config(source.to_string()))?;
    parse_release_version(effective_url)
}

fn parse_release_version(
    effective_url: &str,
) -> std::result::Result<semver::Version, crate::error::MoiError> {
    let tag = effective_url
        .trim_end_matches('/')
        .rsplit('/')
        .next()
        .filter(|tag| !tag.is_empty() && *tag != "latest")
        .ok_or_else(|| {
            crate::error::MoiError::config(format!(
                "could not determine latest release from {effective_url}"
            ))
        })?;
    semver::Version::parse(tag.strip_prefix('v').unwrap_or(tag)).map_err(|source| {
        crate::error::MoiError::config(format!(
            "invalid release version {tag}: {source}"
        ))
    })
}

fn install_latest() -> std::result::Result<(), crate::error::MoiError> {
    let target = target_triple()?;
    let package = format!("moi-{target}");
    let asset = std::env::var("MOI_RELEASE_ASSET")
        .unwrap_or_else(|_| format!("{package}.tar.gz"));
    let repository = std::env::var("MOI_GITHUB_REPOSITORY")
        .unwrap_or_else(|_| "konattsu/moi".to_string());
    let release_base = std::env::var("MOI_RELEASE_BASE").unwrap_or_else(|_| {
        format!("https://github.com/{repository}/releases/latest/download")
    });
    let url = format!("{}/{asset}", release_base.trim_end_matches('/'));
    let tempdir = tempfile::Builder::new()
        .prefix("moi-upgrade-")
        .tempdir()
        .map_err(|source| crate::error::MoiError::io(std::env::temp_dir(), source))?;
    let archive = tempdir.path().join(&asset);
    let checksum = tempdir.path().join(format!("{asset}.sha256"));

    curl_download(&url, &archive)?;
    curl_download(&format!("{url}.sha256"), &checksum)?;
    run_command(
        std::process::Command::new("sha256sum")
            .args(["--check", "--status"])
            .arg(&checksum)
            .current_dir(tempdir.path()),
    )?;
    run_command(
        std::process::Command::new("tar")
            .arg("-xzf")
            .arg(&archive)
            .current_dir(tempdir.path()),
    )?;

    let binary = tempdir.path().join(package).join("moi");
    replace_current_executable(&binary)
}

fn curl_download(
    url: &str,
    destination: &std::path::Path,
) -> std::result::Result<(), crate::error::MoiError> {
    run_command(
        std::process::Command::new("curl")
            .args(["-fsSL", url, "-o"])
            .arg(destination),
    )
}

fn run_command(
    command: &mut std::process::Command,
) -> std::result::Result<(), crate::error::MoiError> {
    let program = command.get_program().to_string_lossy().into_owned();
    let status = command
        .status()
        .map_err(|source| crate::error::MoiError::io(program, source))?;
    if !status.success() {
        return Err(crate::error::MoiError::CommandExit(
            status.code().unwrap_or(1),
        ));
    }
    Ok(())
}

fn replace_current_executable(
    source: &std::path::Path,
) -> std::result::Result<(), crate::error::MoiError> {
    let destination = std::env::current_exe()
        .map_err(|source| crate::error::MoiError::io("current executable", source))?;
    let parent = destination.parent().ok_or_else(|| {
        crate::error::MoiError::config(format!(
            "current executable has no parent directory: {}",
            destination.display()
        ))
    })?;
    let mut replacement = tempfile::NamedTempFile::new_in(parent)
        .map_err(|source| crate::error::MoiError::io(parent, source))?;
    let mut downloaded = std::fs::File::open(source)
        .map_err(|error| crate::error::MoiError::io(source, error))?;
    std::io::copy(&mut downloaded, replacement.as_file_mut())
        .map_err(|error| crate::error::MoiError::io(replacement.path(), error))?;

    let permissions = std::fs::metadata(source)
        .map_err(|error| crate::error::MoiError::io(source, error))?
        .permissions();
    replacement
        .as_file()
        .set_permissions(permissions)
        .map_err(|error| crate::error::MoiError::io(replacement.path(), error))?;
    replacement
        .as_file_mut()
        .sync_all()
        .map_err(|error| crate::error::MoiError::io(replacement.path(), error))?;
    replacement
        .persist(&destination)
        .map_err(|error| crate::error::MoiError::io(&destination, error.error))?;
    Ok(())
}

fn target_triple() -> std::result::Result<&'static str, crate::error::MoiError> {
    match (std::env::consts::OS, std::env::consts::ARCH) {
        ("linux", "x86_64") => Ok("x86_64-unknown-linux-gnu"),
        ("linux", "aarch64") => Ok("aarch64-unknown-linux-gnu"),
        (os, arch) => Err(crate::error::MoiError::config(format!(
            "unsupported platform: {os}/{arch}"
        ))),
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_parse_release_version() {
        let version = super::parse_release_version(
            "https://github.com/konattsu/moi/releases/tag/v1.2.3",
        )
        .unwrap();

        assert_eq!(version, semver::Version::new(1, 2, 3));
    }

    #[test]
    fn test_parse_release_version_without_v_prefix() {
        let version = super::parse_release_version(
            "https://github.com/konattsu/moi/releases/tag/1.2.3/",
        )
        .unwrap();

        assert_eq!(version, semver::Version::new(1, 2, 3));
    }

    #[test]
    fn test_reject_latest_without_redirect() {
        let error = super::parse_release_version(
            "https://github.com/konattsu/moi/releases/latest",
        )
        .unwrap_err();

        assert!(error.to_string().contains("could not determine"));
    }
}
