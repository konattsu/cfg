pub(crate) fn home_dir()
-> std::result::Result<std::path::PathBuf, crate::error::MoiError> {
    std::env::var_os("HOME")
        .map(std::path::PathBuf::from)
        .ok_or_else(|| crate::error::MoiError::config("HOME is not set"))
}

pub(crate) fn expand_home(
    path: &std::path::Path,
) -> std::result::Result<std::path::PathBuf, crate::error::MoiError> {
    let text = path.to_string_lossy();
    if text == "~" {
        return home_dir();
    }
    if let Some(rest) = text.strip_prefix("~/") {
        return Ok(home_dir()?.join(rest));
    }
    Ok(path.to_path_buf())
}
