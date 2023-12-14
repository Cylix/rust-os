use core::fmt;

// reimplement std::print and std::println to print using the VGA display
//
// original std::print and std::println implementation:
//   - https://doc.rust-lang.org/nightly/src/std/macros.rs.html#138-145
//   - https://doc.rust-lang.org/nightly/src/std/macros.rs.html#82-86
//
// refer to:
//   - https://doc.rust-lang.org/nightly/book/ch19-06-macros.html#declarative-macros-with-macro_rules-for-general-metaprogramming
//   - https://os.phil-opp.com/vga-text-mode/#a-println-macro
#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::macros::print::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    () => ($crate::print!("\n"));
    ($($arg:tt)*) => ($crate::print!("{}\n", format_args!($($arg)*)));
}

#[doc(hidden)]
pub fn _print(args: fmt::Arguments) {
    use core::fmt::Write;
    crate::kernel::display::vga::writer::DEFAULT_WRITER.lock().write_fmt(args).unwrap();
}
