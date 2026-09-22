# page_flip_view example

A small app with three tabs:

- **PDF asset**: `PdfFlipBook.asset` with a bundled six-page PDF, previous/next buttons, a page counter and a night mode switch.
- **PDF network**: `PdfFlipBook.network` downloading a PDF from GitHub, with a download progress bar and a retry button.
- **Widgets**: `PageFlipView` with plain coloured pages, to show that any widget can be a page.

Try: drag a page corner, fling, tap the page edges, double tap or pinch to zoom.

```sh
flutter run
```

iOS needs iOS 15 or newer (PDFium).
