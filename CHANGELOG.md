## 0.2.0

- Pinch and double tap zoom (`enableZoom`, `maxScale`, `doubleTapScale`,
  `onZoomChanged`); one finger pans while zoomed and turning pauses.
- PDF pages are re-rendered at the zoom level so text stays sharp.
- `PdfFlipBook.colorFilter` and `PdfFlipBook.nightMode` for night reading.
- Edge taps turn pages immediately; a middle tap waits for a possible
  double tap before calling `onCenterTap`.

## 0.1.0

- `PageFlipView`: book-style pager with a diagonal corner curl that follows
  the finger, edge taps, fling, and `PageFlipController`.
- `PdfFlipBook.file`, `.asset`, `.data`, `.document`: PDF books rendered with
  pdfrx, with a fast preview per page and prefetching of nearby pages.
