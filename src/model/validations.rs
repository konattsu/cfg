pub(in crate::model) fn no_shell_expansion(
    path: &std::path::Path,
    where_: &str,
) -> Result<(), String> {
    if path.to_string_lossy().contains('$') {
        return Err(format!(
            "{where_}: shell variable expansion is not supported"
        ));
    }
    Ok(())
}

pub(in crate::model) fn path_string(
    path: &std::path::Path,
    where_: &str,
) -> Result<(), String> {
    if path.as_os_str().is_empty() {
        return Err(format!("{where_}: must be a non-empty path"));
    }
    no_shell_expansion(path, where_)
}

pub(in crate::model) fn module_relative_path(
    path: &std::path::Path,
    where_: &str,
) -> Result<(), String> {
    path_string(path, where_)?;
    if path.is_absolute()
        || path
            .components()
            .any(|part| matches!(part, std::path::Component::ParentDir))
    {
        return Err(format!(
            "{where_}: must be module-relative and must not contain .."
        ));
    }
    Ok(())
}

pub(in crate::model) fn non_empty_string(
    value: &str,
    where_: &str,
) -> Result<(), String> {
    if value.is_empty() {
        return Err(format!("{where_}: must be a non-empty string"));
    }
    Ok(())
}
