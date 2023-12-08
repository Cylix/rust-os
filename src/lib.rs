// standard rust library is not available on rust-os
#![no_std]

use core::panic::PanicInfo;

// replace the standard library panic_handler
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// hello world
static HELLO: &[u8] = b"Hello World: Welcome to Rust OS!";

#[no_mangle]
pub extern fn rust_kernel() -> ! {
    let vga_buffer = 0xb8000 as *mut u8;
    let visible_screen_offset = 0x140;

    for (i, &byte) in HELLO.iter().enumerate() {
        unsafe {
            // write letter
            *vga_buffer.offset(visible_screen_offset + i as isize * 2) = byte;
            // set color (white foreground, blue background)
            *vga_buffer.offset(visible_screen_offset + i as isize * 2 + 1) = 0x1f;
        }
    }

    loop {}
}
