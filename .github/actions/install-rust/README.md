# install-rust

The `install-rust` action installs Rust toolchain.
There is no stability guarantee for this action, since it's supposed to only be
used in infra managed by us.

## Usage

```yaml
- uses: taiki-e/github-actions/install-rust@master
  with:
    # Default toolchain to install, default value is nightly
    # If the toolchain is nightly (default) and the component is specified,
    # the latest toolchain that specified component is available is selected.
    toolchain: stable
    # Component to install
    component: rustfmt
```
