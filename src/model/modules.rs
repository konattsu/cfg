pub(crate) fn load(
    modules_dir: &std::path::Path,
) -> std::result::Result<
    std::collections::BTreeMap<String, crate::model::Module>,
    crate::error::MoiError,
> {
    if !modules_dir.exists() {
        return Err(crate::error::MoiError::config(format!(
            "modules directory not found: {}",
            modules_dir.display()
        )));
    }
    let mut modules = std::collections::BTreeMap::new();
    for entry in std::fs::read_dir(modules_dir)
        .map_err(|source| crate::error::MoiError::io(modules_dir, source))?
    {
        let entry =
            entry.map_err(|source| crate::error::MoiError::io(modules_dir, source))?;
        let path = entry.path();
        if !path.is_dir() || !path.join("module.toml").is_file() {
            continue;
        }
        let module = load_one(&path)?;
        modules.insert(module.name().as_str().to_string(), module);
    }
    Ok(modules)
}

fn load_one(
    module_dir: &std::path::Path,
) -> std::result::Result<crate::model::Module, crate::error::MoiError> {
    let path = module_dir.join("module.toml");
    let content = std::fs::read_to_string(&path)
        .map_err(|source| crate::error::MoiError::io(&path, source))?;
    let mut module: crate::model::Module =
        toml::from_str(&content).map_err(|source| crate::error::MoiError::Toml {
            path: path.clone(),
            source,
        })?;
    let expected = module_dir
        .file_name()
        .and_then(std::ffi::OsStr::to_str)
        .ok_or_else(|| {
            crate::error::MoiError::config("invalid module directory name")
        })?;
    if module.name().as_str() != expected {
        return Err(crate::error::MoiError::config(format!(
            "{}: name must match directory name ({expected})",
            path.display()
        )));
    }
    module.set_path(module_dir.to_path_buf());
    Ok(module)
}

pub(crate) fn resolve<'a>(
    modules: &'a std::collections::BTreeMap<String, crate::model::Module>,
    requested: &[String],
) -> std::result::Result<Vec<&'a crate::model::Module>, crate::error::MoiError> {
    let targets = if requested.is_empty() {
        modules.keys().cloned().collect::<Vec<_>>()
    } else {
        requested.to_vec()
    };
    for target in &targets {
        if !modules.contains_key(target) {
            return Err(crate::error::MoiError::config(format!(
                "unknown module: {target}"
            )));
        }
    }

    let mut selected = std::collections::BTreeSet::new();
    for target in &targets {
        include(modules, target, &mut Vec::new(), &mut selected)?;
    }

    let mut ordered = Vec::new();
    let mut temporary = std::collections::BTreeSet::new();
    let mut permanent = std::collections::BTreeSet::new();
    for name in &selected {
        visit(
            modules,
            name,
            &selected,
            &mut temporary,
            &mut permanent,
            &mut ordered,
        )?;
    }
    Ok(ordered)
}

fn include(
    modules: &std::collections::BTreeMap<String, crate::model::Module>,
    name: &str,
    stack: &mut Vec<String>,
    selected: &mut std::collections::BTreeSet<String>,
) -> std::result::Result<(), crate::error::MoiError> {
    if stack.iter().any(|item| item == name) {
        let mut cycle = stack.clone();
        cycle.push(name.to_string());
        return Err(crate::error::MoiError::config(format!(
            "dependency cycle: {}",
            cycle.join(" -> ")
        )));
    }
    if selected.contains(name) {
        return Ok(());
    }
    let module = modules.get(name).ok_or_else(|| {
        crate::error::MoiError::config(format!("unknown module: {name}"))
    })?;
    stack.push(name.to_string());
    for dep in module.depends_on() {
        if !modules.contains_key(dep.as_str()) {
            return Err(crate::error::MoiError::config(format!(
                "{name}: unknown dependency: {dep}"
            )));
        }
        include(modules, dep.as_str(), stack, selected)?;
    }
    stack.pop();
    selected.insert(name.to_string());
    Ok(())
}

fn visit<'a>(
    modules: &'a std::collections::BTreeMap<String, crate::model::Module>,
    name: &str,
    selected: &std::collections::BTreeSet<String>,
    temporary: &mut std::collections::BTreeSet<String>,
    permanent: &mut std::collections::BTreeSet<String>,
    ordered: &mut Vec<&'a crate::model::Module>,
) -> std::result::Result<(), crate::error::MoiError> {
    if permanent.contains(name) {
        return Ok(());
    }
    if !temporary.insert(name.to_string()) {
        return Err(crate::error::MoiError::config(format!(
            "dependency cycle at {name}"
        )));
    }
    let module = modules.get(name).ok_or_else(|| {
        crate::error::MoiError::config(format!("unknown module: {name}"))
    })?;
    for dep in module.depends_on() {
        if selected.contains(dep.as_str()) {
            visit(
                modules,
                dep.as_str(),
                selected,
                temporary,
                permanent,
                ordered,
            )?;
        }
    }
    temporary.remove(name);
    permanent.insert(name.to_string());
    ordered.push(module);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_resolve_all_in_dependency_order() {
        let tempdir = tempfile::tempdir().unwrap();
        write_module(tempdir.path(), "core", &[]);
        write_module(tempdir.path(), "git", &["core"]);
        write_module(tempdir.path(), "zsh", &["core"]);

        let modules = load(tempdir.path()).unwrap();
        let ordered = resolve(&modules, &[]).unwrap();
        let names = ordered
            .iter()
            .map(|module| module.name().as_str())
            .collect::<Vec<_>>();

        assert_eq!(names, ["core", "git", "zsh"]);
    }

    #[test]
    fn test_resolve_requested_module_includes_dependency() {
        let tempdir = tempfile::tempdir().unwrap();
        write_module(tempdir.path(), "core", &[]);
        write_module(tempdir.path(), "git", &["core"]);
        write_module(tempdir.path(), "zsh", &["core"]);

        let modules = load(tempdir.path()).unwrap();
        let ordered = resolve(&modules, &[String::from("git")]).unwrap();
        let names = ordered
            .iter()
            .map(|module| module.name().as_str())
            .collect::<Vec<_>>();

        assert_eq!(names, ["core", "git"]);
    }

    #[test]
    fn test_reject_unknown_requested_module() {
        let tempdir = tempfile::tempdir().unwrap();
        write_module(tempdir.path(), "core", &[]);

        let modules = load(tempdir.path()).unwrap();
        let error = resolve(&modules, &[String::from("missing")]).unwrap_err();

        assert!(error.to_string().contains("unknown module: missing"));
    }

    #[test]
    fn test_reject_unknown_dependency() {
        let tempdir = tempfile::tempdir().unwrap();
        write_module(tempdir.path(), "git", &["core"]);

        let modules = load(tempdir.path()).unwrap();
        let error = resolve(&modules, &[]).unwrap_err();

        assert!(error.to_string().contains("git: unknown dependency: core"));
    }

    #[test]
    fn test_reject_dependency_cycle() {
        let tempdir = tempfile::tempdir().unwrap();
        write_module(tempdir.path(), "a", &["b"]);
        write_module(tempdir.path(), "b", &["a"]);

        let modules = load(tempdir.path()).unwrap();
        let error = resolve(&modules, &[]).unwrap_err();

        assert!(error.to_string().contains("dependency cycle"));
    }

    #[test]
    fn test_reject_module_name_mismatch() {
        let tempdir = tempfile::tempdir().unwrap();
        let dir = tempdir.path().join("actual");
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join("module.toml"), "name = \"declared\"\n").unwrap();

        let error = load(tempdir.path()).unwrap_err();

        assert!(
            error
                .to_string()
                .contains("name must match directory name (actual)")
        );
    }

    fn write_module(root: &std::path::Path, name: &str, deps: &[&str]) {
        let dir = root.join(name);
        std::fs::create_dir_all(&dir).unwrap();
        let depends_on = deps
            .iter()
            .map(|dep| format!("\"{dep}\""))
            .collect::<Vec<_>>()
            .join(", ");
        std::fs::write(
            dir.join("module.toml"),
            format!("name = \"{name}\"\ndepends_on = [{depends_on}]\n"),
        )
        .unwrap();
    }
}
