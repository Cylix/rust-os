## Rust OS
Learning stuff by building a tiny OS with Rust.

### Dependencies
* Install [macFUSE](https://osxfuse.github.io/) (required for compiling grub on macOS).
* Download rust standard library source code: `rustup component add rust-src`

### Usage
```bash
# Build kernel
$> make

# Run kernel
$> make run
```

### References
* [Phil Opp's Blog (latest edition)](https://os.phil-opp.com)
* [Phil Opp's Blog (first edition)](https://os.phil-opp.com/edition-1/)
* [OSDev](https://wiki.osdev.org/Main_Page)
