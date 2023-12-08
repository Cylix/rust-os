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

### Rust Target Configuration Notes
Target Configuration can be found in [x86_64-rust-os.json](./x86_64-rust-os.json).

It replicates `x86_64-unknown-linux-gnu`, with the following differences:
* `os=none` (`rust-os` is its own unknown OS)
* `panic-strategy=abort` (disable stack unwinding, as it is not supported with `no_std`)
* `disable-redzone=true` (disable redzone stack pointer optimization to prevent stack corruption)
* `features=-mmx,-sse,+soft-float` (disable SIMD for better performance during interrupts, and use software-emulated floats since it requires SIMD registers otherwise)
* `linker-flavor=ld.lld` and `linker=rust-lld` (use lld cross-platform linker)

For more details, refer to:
* [Phil Opp's Blog (latest edition): Target Specification](https://os.phil-opp.com/minimal-rust-kernel/#target-specification)
* [Phil Opp's Blog (first edition): Rust Setup](https://os.phil-opp.com/set-up-rust/)

### References
* [Phil Opp's Blog (latest edition)](https://os.phil-opp.com)
* [Phil Opp's Blog (first edition)](https://os.phil-opp.com/edition-1/)
* [OSDev](https://wiki.osdev.org/Main_Page)
