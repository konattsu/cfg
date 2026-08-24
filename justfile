set shell := ["bash", "-euo", "pipefail", "-c"]

default: check

# Verify that all dependency licenses satisfy the release policy.
cargo-about:
    cargo about generate --locked --fail --config cargo-about/about.toml cargo-about/about.txt.hbs > /dev/null

# Apply rustfmt formatting.
fmt:
    cargo fmt --all

# Check rustfmt formatting without changing files.
fmt-check:
    cargo fmt --all -- --check

# Apply machine-applicable Clippy fixes and reject remaining warnings.
clippy:
    cargo clippy --fix --locked --allow-dirty --allow-staged --all-targets --all-features -- -D warnings -D clippy::all

# Run Clippy without changing files and reject all warnings.
clippy-check:
    cargo clippy --locked --all-targets --all-features -- -D warnings -D clippy::all

# Run all tests and reject compiler warnings.
test:
    RUSTFLAGS="-Dwarnings" cargo test --locked --all-targets --all-features

# Run the complete non-mutating validation suite.
check: cargo-about fmt-check clippy-check test
