// standard rust library is not available on rust-os
#![no_std]

mod kernel;
mod macros;

use core::panic::PanicInfo;

// replace the standard library panic_handler
#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    loop {}
}

pub fn test_print() {
    for i in 1..31 {
        println!("test string #{}", i)
    }
    print!("test string #32 which is a much longer string that wraps over two different lines to test if the program works properly");
}

#[no_mangle]
pub extern fn _start_rust_kernel() -> ! {
    test_print();
    loop {}
}
