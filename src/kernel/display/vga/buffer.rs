use super::character;

// 2D array buffer abstraction
//   - use constant generics for the buffer size
//   - use repr(transparent) to ensure same data layout as the underlying 2D array
#[repr(transparent)]
pub struct Buffer<const ROWS: usize, const COLS: usize> {
    pub chars: [[character::Character; COLS]; ROWS],
}

impl<const ROWS: usize, const COLS: usize> Buffer<ROWS, COLS> {

    // convenience function to access the buffer size
    pub fn rows(&self) -> usize {
        return ROWS;
    }

    // convenience function to access the buffer size
    pub fn cols(&self) -> usize {
        return COLS;
    }

}
