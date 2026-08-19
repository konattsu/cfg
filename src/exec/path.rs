pub(in crate::exec) fn set_mode(
    path: &std::path::Path,
    mode: crate::model::Mode,
) -> std::result::Result<(), crate::error::MoiError> {
    use std::os::unix::fs::PermissionsExt;

    let permissions = std::fs::Permissions::from_mode(mode.value());
    std::fs::set_permissions(path, permissions)
        .map_err(|source| crate::error::MoiError::io(path, source))
}

pub(in crate::exec) fn shell_quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "'\"'\"'"))
}
