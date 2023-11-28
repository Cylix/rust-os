// standard rust library is not available on rust-os
#![no_std]

// runtimes (c's crt0 and rust's start) is not available on rust-os
#![no_main]

use core::panic::PanicInfo;

// replace the standard library panic_handler
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// replace c's runtime crt0
#[no_mangle]
pub extern "C" fn _start() -> ! {
    main()
}

// hello world
static HELLO: &[u8] = b"Hello World!";

pub fn main() -> ! {
    let vga_buffer = 0xb8000 as *mut u8;

    for (i, &byte) in HELLO.iter().enumerate() {
        unsafe {
            // write letter
            *vga_buffer.offset(i as isize * 2) = byte;
            // set color (cyan)
            *vga_buffer.offset(i as isize * 2 + 1) = 0xb;
        }
    }

    loop {}
}
