// list of supported colors
// 16 colors, encoded on 4-bits (using u8 since u4 doesn't exist)
//
// refer to:
//   - https://wiki.osdev.org/Printing_to_Screen
//   - https://os.phil-opp.com/vga-text-mode/#colors
#[allow(dead_code)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum Color {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    Pink = 13,
    Yellow = 14,
    White = 15,
}

// character color code representation
// encoded on 8 bits:
//   - higher 4 bits: background color
//   - lower 4 bits: foreground color
//
// use repr(transparent) to ensure same data layout as a u8
//
// refer to https://wiki.osdev.org/Printing_to_Screen
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(transparent)]
pub struct ColorCode(u8);

impl ColorCode {
    pub fn new(foreground: Color, background: Color) -> ColorCode {
        ColorCode((background as u8) << 4 | (foreground as u8))
    }
}

// character representation
// encoded on 16 bits (2 bytes):
//   - higher 8 bits: actual character, using code page 437 character set (CP437)
//   - lower 8 bits: color code
//
// use repr(C) to ensure fields ordering
//
// refer to:
//   - https://wiki.osdev.org/Printing_to_Screen
//   - https://en.wikipedia.org/wiki/Code_page_437
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(C)]
pub struct Character {
    pub char: u8,
    pub color: ColorCode,
}
