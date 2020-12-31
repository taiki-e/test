---
name: Bug Report
about: Create a bug report.
labels: C-bug
---

<!--
Thank you for filing a bug report! 🐛 Please provide a short summary of the bug,
along with any information you feel relevant to replicating the bug.
-->

I tried this code:

```rust
<code>
```

I expected to see this happen: *explanation*

Instead, this happened: *explanation*

### Meta

`rustc --version --verbose`:

```
<version>
```

<!--
`cargo tree` subcommand is available by default since Rust 1.44.
If you using an older compiler, you could install it from crates.io:
https://crates.io/crates/cargo-tree.
-->

`cargo tree | grep <package-name>`:

<!-- or
`cargo tree -p <package-name>`: -->
<details><summary>output</summary>
<p>

```
<dependencies>
```

</p>
</details>

Platform:

<!--
The output of `uname -a` (UNIX), or version and 32 or 64-bit (Windows)
-->
