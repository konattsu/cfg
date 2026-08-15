#!/usr/bin/env bash
set -euo pipefail

branch="${MOI_BRANCH:-main}"
self_url="${MOI_SELF_URL:-https://raw.githubusercontent.com/konattsu/moi/main/moi.sh}"
self_path="${MOI_SELF_PATH:-$HOME/.local/bin/moi}"
config_path="$HOME/.config/moi/config.toml"
default_folder_name="environments"
default_source="https://github.com/konattsu/moi.git"
original_args=("$@")

usage() {
  cat >&2 <<'EOF'
usage: moi [--environment ENV] [--folder-name NAME] [--source SOURCE] plan|apply [options] [module ...]
EOF
}

self_update() {
  if [[ "${MOI_NO_SELF_UPDATE:-}" == "1" ]]; then
    return
  fi
  command -v curl >/dev/null 2>&1 || return

  local tmp
  tmp="$(mktemp)"
  if ! curl -fsSL "$self_url" -o "$tmp"; then
    rm -f "$tmp"
    return
  fi

  if [[ -f "$self_path" ]] && cmp -s "$tmp" "$self_path"; then
    rm -f "$tmp"
    return
  fi

  mkdir -p "$(dirname "$self_path")"
  install -m 755 "$tmp" "$self_path"
  rm -f "$tmp"

  if [[ "${MOI_REEXECED:-}" != "1" ]]; then
    MOI_REEXECED=1 exec "$self_path" "$@"
  fi
}

read_config_value() {
  local key="$1"
  [[ -f "$config_path" ]] || return 0
  python3 -c 'import pathlib, sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
path = pathlib.Path(sys.argv[1])
key = sys.argv[2]
data = tomllib.loads(path.read_text())
value = data.get(key)
if value is not None:
    if not isinstance(value, str) or value == "":
        raise SystemExit(f"error: {path}: {key} must be a non-empty string")
    print(value)
' "$config_path" "$key"
}

require_setting() {
  local value="$1"
  local name="$2"
  local env_name="$3"
  if [[ -z "$value" ]]; then
    echo "error: missing required setting: $name (use --${name//_/-} or $env_name or $config_path)" >&2
    exit 1
  fi
}

environment_arg=""
folder_name_arg=""
source_arg=""
command_name=""
command_args=()

while (($# > 0)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --environment)
      [[ $# -ge 2 ]] || { echo "error: --environment requires a value" >&2; exit 1; }
      environment_arg="$2"
      shift 2
      ;;
    --environment=*)
      environment_arg="${1#*=}"
      shift
      ;;
    --folder-name)
      [[ $# -ge 2 ]] || { echo "error: --folder-name requires a value" >&2; exit 1; }
      folder_name_arg="$2"
      shift 2
      ;;
    --folder-name=*)
      folder_name_arg="${1#*=}"
      shift
      ;;
    --source)
      [[ $# -ge 2 ]] || { echo "error: --source requires a value" >&2; exit 1; }
      source_arg="$2"
      shift 2
      ;;
    --source=*)
      source_arg="${1#*=}"
      shift
      ;;
    plan|apply)
      if [[ -n "$command_name" ]]; then
        command_args+=("$1")
      else
        command_name="$1"
      fi
      shift
      ;;
    *)
      command_args+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$command_name" ]]; then
  usage
  echo "error: missing required operation: plan or apply" >&2
  exit 1
fi

self_update "${original_args[@]}"

need_commands=()
command -v python3 >/dev/null 2>&1 || need_commands+=(python3)

if ((${#need_commands[@]} > 0)); then
  echo "error: missing required commands: ${need_commands[*]}" >&2
  exit 1
fi

environment="${environment_arg:-${MOI_ENVIRONMENT:-$(read_config_value default_environment)}}"
folder_name="${folder_name_arg:-${MOI_FOLDER_NAME:-$(read_config_value default_folder_name)}}"
source="${source_arg:-${MOI_SOURCE:-$(read_config_value default_source)}}"
folder_name="${folder_name:-$default_folder_name}"
source="${source:-$default_source}"

require_setting "$environment" "environment" "MOI_ENVIRONMENT"

case "$source" in
  https://*)
    command -v git >/dev/null 2>&1 || {
      echo "error: missing required command: git" >&2
      exit 1
    }
    ;;
  file:///*)
    ;;
  *)
    echo 'error: source must start with "https://" or "file:///"' >&2
    exit 1
    ;;
esac

case "$folder_name" in
  /*|*../*|../*|*"/.."|*"/../"*)
    echo "error: folder_name must be repository-relative and must not contain .." >&2
    exit 1
    ;;
esac

clone_dir="$(mktemp -d)"
repo_root="$clone_dir"
trap 'rm -rf "$clone_dir"' EXIT

case "$source" in
  https://*)
    git clone --depth 1 --branch "$branch" "$source" "$clone_dir"
    ;;
  file:///*)
    repo_root="${source#file://}"
    ;;
esac

if [[ ! -x "$repo_root/scripts/$command_name.sh" ]]; then
  echo "error: command entry point not found or not executable: $repo_root/scripts/$command_name.sh" >&2
  exit 1
fi

if [[ ! -f "$config_path" ]]; then
  mkdir -p "$(dirname "$config_path")"
  {
    printf 'default_environment = "%s"\n' "$environment"
    printf 'default_folder_name = "%s"\n' "$folder_name"
    printf 'default_source = "%s"\n' "$source"
  } >"$config_path"
fi

exec "$repo_root/scripts/$command_name.sh" \
  --environment "$environment" \
  --folder-name "$folder_name" \
  --source "$source" \
  "${command_args[@]}"
