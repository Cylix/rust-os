use core::fmt;
use core::ptr;
use lazy_static::lazy_static;
use spin::Mutex;

use super::buffer;
use super::character;

// vga screen size is 25 rows by 80 columns in text mode
// actual buffer representation is larger since each character is 2 bytes
const VGA_SCREEN_ROWS: usize = 25;
const VGA_SCREEN_COLS: usize = 80;

// vga screen cursor position, expressed using col and row number
#[derive(Default)]
struct Cursor {
    col: usize,
    row: usize,
}

// writer abstraction
//   - write to the given VGA buffer
//   - keep track of current cursor position
//   - handle utf8->CP437 conversion
//   - handle line breaks, wrapping, and scrolling
//
// refer to implementation for further details
pub struct Writer<'a> {
    cursor: Cursor,
    color: character::ColorCode,
    buffer: &'a mut buffer::Buffer<VGA_SCREEN_ROWS, VGA_SCREEN_COLS>,
}

// initialize a default writer pointing to the VGA buffer at 0xb8000
//   - use a lazy static since rust won't let us convert raw pointers to references at compile time
//   - use a mutex
//     - needed to make a static with interior mutability
//     - using a spinlock mutex to work around the fact our kernel has no concept of threads and blocking support
//
// refer to:
//   - https://wiki.osdev.org/Printing_to_Screen
//   - https://doc.rust-lang.org/book/ch15-05-interior-mutability.html
//   - https://os.phil-opp.com/vga-text-mode/#lazy-statics
//   - https://os.phil-opp.com/vga-text-mode/#spinlocks
lazy_static! {
    pub static ref DEFAULT_WRITER: Mutex<Writer<'static>> = Mutex::new(Writer {
        cursor: Default::default(),
        color: character::ColorCode::new(character::Color::White, character::Color::Black),
        buffer: unsafe { &mut *(0xb8000 as *mut buffer::Buffer<VGA_SCREEN_ROWS, VGA_SCREEN_COLS>) },
    });
}

impl Writer<'_> {

    // vga is using the "code page 437" character set (CP437), which differs from ascii and utf8
    //   - non-printable ascii characters would likely map to random printable CP437 characters
    //     for example, ascii bell (0x07) maps to '•' CP437, which is completely unrelated
    //   - thus, replace any non-printable ascii character by a printable '■' CP437 character (0xfe)
    //   - additionally, implement special handling for '\n' for line breaks and scrolling
    //
    // once converted to CP437, delegate to write_cp437_char
    //
    // refer to:
    //   - https://www.fileformat.info/info/unicode/utf8.htm
    //   - https://en.wikipedia.org/wiki/Code_page_437
    //   - https://en.wikipedia.org/wiki/ASCII
    pub fn write_ascii_char(&mut self, ascii_byte: u8) {
        match ascii_byte {
            // line break
            b'\n' => self.new_line(),

            // printable ascii characters range
            0x20..=0x7e => self.write_cp437_char(ascii_byte),

            // non-printable ascii characters
            _ => self.write_cp437_char(0xfe), // '■'
        }
    }

    // print a single "code page 437" (CP437) character
    // implement automatic line wrapping and scrolling
    pub fn write_cp437_char(&mut self, cp437_char: u8) {
        // detect end-of-line
        if self.cursor.col >= self.buffer.cols() {
            self.new_line();
        }

        // write character to the buffer
        // use write_volatile to notify compiler of external side effects and prevent unwanted optimizations
        // https://doc.rust-lang.org/nightly/core/ptr/fn.write_volatile.html
        unsafe {
            ptr::write_volatile(&mut self.buffer.chars[self.cursor.row][self.cursor.col] as *mut character::Character, character::Character {
                char: cp437_char,
                color: self.color,
            });
        }

        // move cursor
        self.cursor.col += 1;
    }

    // jump to the next line
    // implement automatic scrolling if last line of the screen is reached
    fn new_line(&mut self) {
        // last screen line not reached yet: jump to the next line
        if self.cursor.row < self.buffer.rows() - 1 {
            self.cursor.row += 1;
            self.cursor.col = 0;
        }
        // last screen line reached: scroll down
        else {
            // move content up one line
            for row in 0..(self.buffer.rows() - 1) {
                for col in 0..self.buffer.cols() {

                    // use read_volatile & write_volatile to notify compiler of external side effects and prevent unwanted optimizations
                    // https://doc.rust-lang.org/nightly/core/ptr/fn.read_volatile.html
                    // https://doc.rust-lang.org/nightly/core/ptr/fn.write_volatile.html
                    unsafe {
                        ptr::write_volatile(
                            &mut self.buffer.chars[row][col] as *mut character::Character,
                            ptr::read_volatile(&self.buffer.chars[row + 1][col] as *const character::Character)
                        );
                    }
                }
            }

            // clear last row
            self.clear_row(self.cursor.row);

            // move cursor back to the beginning of the row
            self.cursor.col = 0;
        }
    }

    // clear the desired row by writing spaces to it
    fn clear_row(&mut self, row: usize) {
        for col in 0..self.buffer.cols() {
            // use write_volatile to notify compiler of external side effects and prevent unwanted optimizations
            // https://doc.rust-lang.org/nightly/core/ptr/fn.write_volatile.html
            unsafe {
                ptr::write_volatile(&mut self.buffer.chars[row][col] as *mut character::Character, character::Character {
                    char: 0x20, // ' '
                    color: self.color,
                });
            }
        }
    }

}

// todo documentation
// It would be nice to support Rust’s formatting macros, too. That way, we can easily print different types, like integers or floats. To support them, we need to implement the core::fmt::Write trait. The only required method of this trait is write_str, which looks quite similar to our write_string method, just with a fmt::Result return type:
// https://doc.rust-lang.org/nightly/core/fmt/trait.Write.html
// provides:
//   - write_str
//   - write_char
//   - write_fmt
impl fmt::Write for Writer<'_> {

    // write string
    // loop over the string and delegate to self.write_ascii_char for each character
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for ascii_byte in s.bytes() {
            self.write_ascii_char(ascii_byte)
        }

        Ok(())
    }

}
