#!/usr/bin/env python3
import argparse
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:
    try:
        import tomli as tomllib  # type: ignore[import-not-found]
    except ModuleNotFoundError:
        tomllib = None  # type: ignore[assignment]


REPO_ROOT = Path(__file__).resolve().parents[1]
MODULES_DIR = REPO_ROOT / "modules"
EXECUTABLE_RE = re.compile(r"^[A-Za-z0-9._+-]+$")
MODE_RE = re.compile(r"^[0-7]{3,4}$")
BLOCK_COMMENT = "#"


class ConfigError(Exception):
    pass


@dataclass
class Command:
    run: str
    unless: str | None = None
    requires: list[str] = field(default_factory=list)


@dataclass
class Module:
    name: str
    path: Path
    packages_apt: list[str] = field(default_factory=list)
    dirs: list[dict[str, Any]] = field(default_factory=list)
    files: list[dict[str, Any]] = field(default_factory=list)
    blocks: list[dict[str, Any]] = field(default_factory=list)
    artifacts: list[dict[str, Any]] = field(default_factory=list)
    commands: list[Command] = field(default_factory=list)
    env_path_prepend: list[str] = field(default_factory=list)
    depends_on: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)


def fail(message: str) -> None:
    raise ConfigError(message)


def load_toml(path: Path) -> dict[str, Any]:
    if tomllib is None:
        fail("TOML support requires Python 3.11+ or the tomli package")
    try:
        with path.open("rb") as f:
            value = tomllib.load(f)
    except tomllib.TOMLDecodeError as e:
        fail(f"{path}: invalid TOML: {e}")
    if not isinstance(value, dict):
        fail(f"{path}: module.toml must be a table")
    return value


def require_string(value: Any, where: str) -> str:
    if not isinstance(value, str) or value == "":
        fail(f"{where}: must be a non-empty string")
    return value


def require_string_list(value: Any, where: str) -> list[str]:
    if value is None:
        return []
    if not isinstance(value, list):
        fail(f"{where}: must be a list")
    return [require_string(v, f"{where}[]") for v in value]


def validate_mode(value: Any, where: str) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str):
        fail(f'{where}: mode must be a quoted octal string, for example "755"')
    if not MODE_RE.fullmatch(value):
        fail(f'{where}: invalid mode "{value}"')
    return value


def validate_executable(value: str, where: str) -> str:
    if not EXECUTABLE_RE.fullmatch(value):
        fail(f'{where}: invalid executable name "{value}"')
    return value


def expand_home(path: str) -> Path:
    if path == "~":
        return Path.home()
    if path.startswith("~/"):
        return Path.home() / path[2:]
    return Path(path)


def validate_path_no_shell_expansion(path: str, where: str) -> str:
    if "$" in path:
        fail(f"{where}: shell variable expansion is not supported")
    return path


def parse_module(module_dir: Path) -> Module:
    path = module_dir / "module.toml"
    data = load_toml(path)
    allowed = {
        "name",
        "packages",
        "dirs",
        "files",
        "blocks",
        "artifacts",
        "commands",
        "env",
        "depends_on",
        "notes",
    }
    unknown = sorted(set(data) - allowed)
    if unknown:
        fail(f"{path}: unknown keys: {', '.join(unknown)}")

    name = require_string(data.get("name"), f"{path}: name")
    if name != module_dir.name:
        fail(f"{path}: name must match directory name ({module_dir.name})")

    packages_apt: list[str] = []
    packages = data.get("packages", {})
    if packages:
        if not isinstance(packages, dict):
            fail(f"{path}: packages must be a mapping")
        unknown_packages = sorted(set(packages) - {"apt"})
        if unknown_packages:
            fail(f"{path}: unknown packages keys: {', '.join(unknown_packages)}")
        packages_apt = require_string_list(packages.get("apt"), f"{path}: packages.apt")

    dirs = parse_path_items(data.get("dirs"), path, "dirs", src_required=False)
    files = parse_path_items(data.get("files"), path, "files", src_required=True)
    blocks = parse_blocks(data.get("blocks"), path)
    artifacts = parse_artifacts(data.get("artifacts"), path)
    commands = parse_commands(data.get("commands"), path)

    env_path_prepend: list[str] = []
    env = data.get("env", {})
    if env:
        if not isinstance(env, dict):
            fail(f"{path}: env must be a mapping")
        unknown_env = sorted(set(env) - {"path_prepend"})
        if unknown_env:
            fail(f"{path}: unknown env keys: {', '.join(unknown_env)}")
        env_path_prepend = require_string_list(env.get("path_prepend"), f"{path}: env.path_prepend")
        for i, item in enumerate(env_path_prepend):
            validate_path_no_shell_expansion(item, f"{path}: env.path_prepend[{i}]")

    depends_on = require_string_list(data.get("depends_on"), f"{path}: depends_on")
    notes = require_string_list(data.get("notes"), f"{path}: notes")

    return Module(
        name=name,
        path=module_dir,
        packages_apt=packages_apt,
        dirs=dirs,
        files=files,
        blocks=blocks,
        artifacts=artifacts,
        commands=commands,
        env_path_prepend=env_path_prepend,
        depends_on=depends_on,
        notes=notes,
    )


def parse_path_items(value: Any, path: Path, key: str, src_required: bool) -> list[dict[str, Any]]:
    if value is None:
        return []
    if not isinstance(value, list):
        fail(f"{path}: {key} must be a list")
    items: list[dict[str, Any]] = []
    for idx, item in enumerate(value):
        where = f"{path}: {key}[{idx}]"
        if not isinstance(item, dict):
            fail(f"{where}: must be a mapping")
        allowed = {"src", "dst", "mode"} if src_required else {"path", "mode"}
        unknown = sorted(set(item) - allowed)
        if unknown:
            fail(f"{where}: unknown keys: {', '.join(unknown)}")
        parsed: dict[str, Any] = {}
        if src_required:
            parsed["src"] = require_string(item.get("src"), f"{where}.src")
            if Path(parsed["src"]).is_absolute():
                fail(f"{where}.src: must be module-relative")
            parsed["dst"] = validate_path_no_shell_expansion(require_string(item.get("dst"), f"{where}.dst"), f"{where}.dst")
        else:
            parsed["path"] = validate_path_no_shell_expansion(require_string(item.get("path"), f"{where}.path"), f"{where}.path")
        mode = validate_mode(item.get("mode"), f"{where}.mode")
        if mode is not None:
            parsed["mode"] = mode
        items.append(parsed)
    return items


def parse_blocks(value: Any, path: Path) -> list[dict[str, str]]:
    if value is None:
        return []
    if not isinstance(value, list):
        fail(f"{path}: blocks must be a list")
    blocks: list[dict[str, str]] = []
    for idx, item in enumerate(value):
        where = f"{path}: blocks[{idx}]"
        if not isinstance(item, dict):
            fail(f"{where}: must be a mapping")
        allowed = {"src", "dst", "marker"}
        unknown = sorted(set(item) - allowed)
        if unknown:
            fail(f"{where}: unknown keys: {', '.join(unknown)}")
        src = require_string(item.get("src"), f"{where}.src")
        if Path(src).is_absolute():
            fail(f"{where}.src: must be module-relative")
        dst = validate_path_no_shell_expansion(require_string(item.get("dst"), f"{where}.dst"), f"{where}.dst")
        marker = require_string(item.get("marker"), f"{where}.marker")
        if ">>>" in marker or "\n" in marker:
            fail(f"{where}.marker: must not contain >>> or newline")
        blocks.append({"src": src, "dst": dst, "marker": marker})
    return blocks


def parse_artifacts(value: Any, path: Path) -> list[dict[str, Any]]:
    if value is None:
        return []
    if not isinstance(value, list):
        fail(f"{path}: artifacts must be a list")
    for idx, item in enumerate(value):
        where = f"{path}: artifacts[{idx}]"
        if not isinstance(item, dict):
            fail(f"{where}: must be a mapping")
        allowed = {"name", "url", "extract", "bin", "dst"}
        unknown = sorted(set(item) - allowed)
        if unknown:
            fail(f"{where}: unknown keys: {', '.join(unknown)}")
        require_string(item.get("name"), f"{where}.name")
        require_string(item.get("url"), f"{where}.url")
        validate_path_no_shell_expansion(require_string(item.get("dst"), f"{where}.dst"), f"{where}.dst")
        if "extract" in item and not isinstance(item["extract"], bool):
            fail(f"{where}.extract: must be a boolean")
        if item.get("extract") and "bin" not in item:
            fail(f"{where}.bin: required when extract is true")
        if "bin" in item:
            require_string(item.get("bin"), f"{where}.bin")
    return value


def parse_commands(value: Any, path: Path) -> list[Command]:
    if value is None:
        return []
    if not isinstance(value, list):
        fail(f"{path}: commands must be a list")
    commands: list[Command] = []
    for idx, item in enumerate(value):
        where = f"{path}: commands[{idx}]"
        if not isinstance(item, dict):
            fail(f"{where}: must be a mapping")
        allowed = {"run", "unless", "requires"}
        unknown = sorted(set(item) - allowed)
        if unknown:
            fail(f"{where}: unknown keys: {', '.join(unknown)}")
        run = require_string(item.get("run"), f"{where}.run")
        unless = item.get("unless")
        if unless is not None:
            unless = require_string(unless, f"{where}.unless")
        requires = require_string_list(item.get("requires"), f"{where}.requires")
        requires = [validate_executable(v, f"{where}.requires[]") for v in requires]
        commands.append(Command(run=run, unless=unless, requires=requires))
    return commands


def load_modules() -> dict[str, Module]:
    modules: dict[str, Module] = {}
    if not MODULES_DIR.exists():
        fail(f"modules directory not found: {MODULES_DIR}")
    for module_dir in sorted(MODULES_DIR.iterdir()):
        if not module_dir.is_dir():
            continue
        if not (module_dir / "module.toml").exists():
            continue
        module = parse_module(module_dir)
        modules[module.name] = module
    return modules


def resolve_modules(modules: dict[str, Module], requested: list[str]) -> list[Module]:
    targets = requested or sorted(modules)
    for name in targets:
        if name not in modules:
            fail(f"unknown module: {name}")

    selected: set[str] = set()

    def include(name: str, stack: list[str]) -> None:
        if name in stack:
            fail(f"dependency cycle: {' -> '.join(stack + [name])}")
        if name in selected:
            return
        module = modules[name]
        for dep in module.depends_on:
            if dep not in modules:
                fail(f"{name}: unknown dependency: {dep}")
            include(dep, stack + [name])
        selected.add(name)

    for target in targets:
        include(target, [])

    ordered: list[Module] = []
    temporary: set[str] = set()
    permanent: set[str] = set()

    def visit(name: str) -> None:
        if name in permanent:
            return
        if name in temporary:
            fail(f"dependency cycle at {name}")
        temporary.add(name)
        for dep in modules[name].depends_on:
            if dep in selected:
                visit(dep)
        temporary.remove(name)
        permanent.add(name)
        ordered.append(modules[name])

    for name in sorted(selected):
        visit(name)
    return ordered


def collect_apt_packages(modules: list[Module]) -> list[str]:
    seen: set[str] = set()
    packages: list[str] = []
    for module in modules:
        for package in module.packages_apt:
            if package not in seen:
                seen.add(package)
                packages.append(package)
    return packages


def apply_env(module: Module) -> None:
    if not module.env_path_prepend:
        return
    current = os.environ.get("PATH", "")
    paths = [str(expand_home(p)) for p in module.env_path_prepend]
    os.environ["PATH"] = os.pathsep.join(paths + [current])


def run_bash(command: str, cwd: Path, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", "-c", command],
        cwd=str(cwd),
        env=os.environ.copy(),
        text=True,
        check=check,
    )


def load_nvm_environment() -> bool:
    nvm_script = Path.home() / ".nvm" / "nvm.sh"
    if not nvm_script.is_file():
        return False
    command = '. "$HOME/.nvm/nvm.sh" >/dev/null 2>&1 && env -0'
    result = subprocess.run(
        ["bash", "-c", command],
        env=os.environ.copy(),
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode != 0:
        return False
    for entry in result.stdout.split(b"\0"):
        if not entry or b"=" not in entry:
            continue
        key, value = entry.split(b"=", 1)
        os.environ[key.decode()] = value.decode(errors="surrogateescape")
    return True


def ensure_command(command: str) -> None:
    if shutil.which(command, path=os.environ.get("PATH")):
        return
    if command in {"node", "npm", "npx"}:
        load_nvm_environment()
        if shutil.which(command, path=os.environ.get("PATH")):
            return
    fail(f"required command not found: {command}")


def apply_dirs(module: Module, dry_run: bool) -> None:
    for item in module.dirs:
        path = expand_home(item["path"])
        mode = item.get("mode")
        print(f"dir  {path}" + (f" mode={mode}" if mode else ""))
        if dry_run:
            continue
        path.mkdir(parents=True, exist_ok=True)
        if mode:
            path.chmod(int(mode, 8))


def apply_files(module: Module, dry_run: bool) -> None:
    for item in module.files:
        src = module.path / item["src"]
        dst = expand_home(item["dst"])
        mode = item.get("mode")
        if not src.is_file():
            fail(f"{module.name}: file source not found: {src}")
        print(f"file {src} -> {dst}" + (f" mode={mode}" if mode else ""))
        if dry_run:
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        if mode:
            dst.chmod(int(mode, 8))


def block_text(marker: str, content: str) -> str:
    if content and not content.endswith("\n"):
        content += "\n"
    return f"{BLOCK_COMMENT} >>> {marker} >>>\n{content}{BLOCK_COMMENT} <<< {marker} <<<\n"


def apply_blocks(module: Module, dry_run: bool) -> None:
    for item in module.blocks:
        src = module.path / item["src"]
        dst = expand_home(item["dst"])
        marker = item["marker"]
        if not src.is_file():
            fail(f"{module.name}: block source not found: {src}")
        content = src.read_text(encoding="utf-8")
        print(f"block {src} -> {dst} marker={marker}")
        if dry_run:
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        existing = dst.read_text(encoding="utf-8") if dst.exists() else ""
        updated = replace_or_append_block(existing, marker, content)
        dst.write_text(updated, encoding="utf-8")


def replace_or_append_block(existing: str, marker: str, content: str) -> str:
    start_line = f"{BLOCK_COMMENT} >>> {marker} >>>"
    end_line = f"{BLOCK_COMMENT} <<< {marker} <<<"
    lines = existing.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.rstrip("\n") == start_line]
    ends = [i for i, line in enumerate(lines) if line.rstrip("\n") == end_line]
    if len(starts) != len(ends):
        fail(f"marker block is unbalanced: {marker}")
    if len(starts) > 1:
        fail(f"marker block appears multiple times: {marker}")
    replacement = block_text(marker, content)
    if not starts:
        prefix = existing
        if prefix and not prefix.endswith("\n"):
            prefix += "\n"
        while prefix and not prefix.endswith("\n\n\n"):
            prefix += "\n"
        return prefix + replacement
    start = starts[0]
    end = ends[0]
    if start > end:
        fail(f"marker block is invalid: {marker}")
    return "".join(lines[:start]) + replacement + "".join(lines[end + 1 :])


def apply_artifacts(module: Module, dry_run: bool) -> None:
    for item in module.artifacts:
        name = item["name"]
        url = item["url"]
        dst = expand_home(item["dst"])
        print(f"artifact {module.name}:{name} {url} -> {dst}")
        if dry_run:
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="moi-artifact-") as tmp:
            tmp_dir = Path(tmp)
            download = tmp_dir / "download"
            urllib.request.urlretrieve(url, download)
            if item.get("extract", False):
                extracted = tmp_dir / "extract"
                extracted.mkdir()
                extract_archive(download, extracted)
                source = find_extracted_binary(extracted, item["bin"])
                shutil.copyfile(source, dst)
                dst.chmod(0o755)
            else:
                shutil.copyfile(download, dst)


def extract_archive(archive: Path, dst: Path) -> None:
    if zipfile.is_zipfile(archive):
        with zipfile.ZipFile(archive) as zf:
            for member in zf.infolist():
                target = (dst / member.filename).resolve()
                if not str(target).startswith(str(dst.resolve()) + os.sep):
                    fail(f"unsafe zip member path: {member.filename}")
            zf.extractall(dst)
        return
    if tarfile.is_tarfile(archive):
        with tarfile.open(archive) as tf:
            for member in tf.getmembers():
                target = (dst / member.name).resolve()
                if not str(target).startswith(str(dst.resolve()) + os.sep):
                    fail(f"unsafe tar member path: {member.name}")
            tf.extractall(dst)
        return
    fail(f"unsupported artifact archive: {archive}")


def find_extracted_binary(root: Path, name: str) -> Path:
    matches = [path for path in root.rglob(name) if path.is_file()]
    if not matches:
        fail(f"artifact binary not found after extraction: {name}")
    if len(matches) > 1:
        fail(f"artifact binary matched multiple files after extraction: {name}")
    return matches[0]


def apply_commands(module: Module, dry_run: bool, ignore_unless: bool = False) -> None:
    for idx, command in enumerate(module.commands, start=1):
        for required in command.requires:
            print(f"require {required}")
            if not dry_run:
                ensure_command(required)
        if command.unless and not ignore_unless:
            print(f"unless command[{idx}]")
            if not dry_run:
                result = run_bash(command.unless, module.path, check=False)
                if result.returncode == 0:
                    print(f"skip command[{idx}]")
                    continue
        print(f"run command[{idx}]")
        if not dry_run:
            run_bash(command.run, module.path, check=True)


def print_plan(modules: list[Module]) -> None:
    packages = collect_apt_packages(modules)
    print("Modules:")
    for module in modules:
        print(f"  - {module.name}")
    print()
    print("APT packages:")
    if packages:
        for package in packages:
            print(f"  - {package}")
    else:
        print("  (none)")
    print()
    print("Operations:")
    for module in modules:
        print(f"[{module.name}]")
        apply_env(module)
        apply_dirs(module, dry_run=True)
        apply_artifacts(module, dry_run=True)
        apply_files(module, dry_run=True)
        apply_blocks(module, dry_run=True)
        for command in module.commands:
            for required in command.requires:
                print(f"require {required}")
            if command.unless:
                print("unless ...")
            print("run ...")
    notes = [note for module in modules for note in module.notes]
    if notes:
        print()
        print("Notes:")
        for note in notes:
            print(f"  - {note}")


def apply(modules: list[Module], ignore_unless: bool = False) -> None:
    packages = collect_apt_packages(modules)
    if packages:
        print("apt update")
        run_bash("sudo apt update", REPO_ROOT, check=True)
        quoted = " ".join(packages)
        print(f"apt install {quoted}")
        run_bash(f"sudo apt install -y {quoted}", REPO_ROOT, check=True)

    for module in modules:
        print(f"==> {module.name}")
        apply_env(module)
        apply_dirs(module, dry_run=False)
        apply_artifacts(module, dry_run=False)
        apply_files(module, dry_run=False)
        apply_blocks(module, dry_run=False)
        apply_commands(module, dry_run=False, ignore_unless=ignore_unless)

    notes = [note for module in modules for note in module.notes]
    if notes:
        print()
        print("Manual follow-up:")
        for note in notes:
            print(f"- {note}")


def main() -> int:
    parser = argparse.ArgumentParser(description="moi module planner/applicator")
    subparsers = parser.add_subparsers(dest="command", required=True)
    plan_parser = subparsers.add_parser("plan")
    plan_parser.add_argument("modules", nargs="*", help="module names; defaults to all modules")
    apply_parser = subparsers.add_parser("apply")
    apply_parser.add_argument(
        "--ignore-unless",
        action="store_true",
        help="run commands without evaluating commands[].unless",
    )
    apply_parser.add_argument("modules", nargs="*", help="module names; defaults to all modules")
    args = parser.parse_args()

    try:
        modules = load_modules()
        ordered = resolve_modules(modules, args.modules)
        if args.command == "plan":
            print_plan(ordered)
        else:
            apply(ordered, ignore_unless=args.ignore_unless)
    except ConfigError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as e:
        print(f"error: command failed with exit code {e.returncode}", file=sys.stderr)
        return e.returncode or 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
