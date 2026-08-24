#!/usr/bin/env bash
set -euo pipefail

version="${CARGO_ABOUT_VERSION:-0.9.2}"

case "$(uname -m)" in
  x86_64)
    target="x86_64-unknown-linux-musl"
    ;;
  aarch64 | arm64)
    target="aarch64-unknown-linux-musl"
    ;;
  *)
    echo "unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

archive="cargo-about-${version}-${target}.tar.gz"
base_url="https://github.com/EmbarkStudios/cargo-about/releases/download/${version}"
install_dir="${CARGO_HOME:-${HOME}/.cargo}/bin"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

curl --fail --location --silent --show-error \
  --output "${work_dir}/${archive}" \
  "${base_url}/${archive}"
curl --fail --location --silent --show-error \
  --output "${work_dir}/${archive}.sha256" \
  "${base_url}/${archive}.sha256"

(
  cd "$work_dir"
  printf '%s  %s\n' "$(cat "${archive}.sha256")" "$archive" | sha256sum --check --status
  tar --extract --gzip --file "$archive"
)

mkdir -p "$install_dir"
install -m 0755 \
  "${work_dir}/cargo-about-${version}-${target}/cargo-about" \
  "${install_dir}/cargo-about"
