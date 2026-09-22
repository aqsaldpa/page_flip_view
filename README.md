# page_flip_view

<p align="center"><img src="https://raw.githubusercontent.com/aqsaldpa/page_flip_view/main/doc/demo.gif" width="340" alt="A PDF page being turned with a diagonal corner curl"></p>

Turn pages like a real book or magazine. The page corner lifts diagonally, follows your finger, and falls back or turns over when you let go. Works with any widgets, and with PDF files out of the box.

- Diagonal corner curl that tracks the finger (top or bottom corner, whichever you grab)
- Release past the middle or fling to turn; otherwise the page falls back
- Tap the page edges to turn, tap the middle for your own action (show a toolbar, for example)
- Back of the turning page shows the page faintly through the paper, with soft fold shadows
- Pinch or double tap to zoom; PDF pages are re-rendered sharp at the zoom level
- Night mode for PDFs with one line: `colorFilter: PdfFlipBook.nightMode`
- `PageFlipController` for next / previous / jump from buttons or sliders
- PDF books with no spinner while turning: a small preview appears at once and sharpens a moment later

## Install

```yaml
dependencies:
  page_flip_view:
    git:
      url: https://github.com/aqsaldpa/page_flip_view.git
      ref: v0.2.0
```

## Any widgets

```dart
import 'package:page_flip_view/page_flip_view.dart';

PageFlipView(
  itemCount: pages.length,
  itemBuilder: (context, index) => Image.asset(pages[index]),
)
```

## PDF

```dart
import 'package:page_flip_view/pdf.dart';

PdfFlipBook.asset('assets/book.pdf')
PdfFlipBook.file('/path/to/book.pdf')
PdfFlipBook.data(bytes)            // after downloading or decrypting
PdfFlipBook.document(pdfDocument)  // a pdfrx PdfDocument you opened yourself
```

That is all you need. Loading, rendering, caching and cleanup are handled for you.

## Control it from code

```dart
final controller = PageFlipController();

PdfFlipBook.file(
  path,
  controller: controller,
  onLoaded: (pageCount) => setState(() => total = pageCount),
  onPageChanged: (page) => saveLastRead(page),
  onCenterTap: toggleToolbar,
);

controller.next();      // animated turn forward
controller.previous();  // animated turn back
controller.jumpTo(12);  // instant
controller.page;        // current page, zero based (the controller is a ChangeNotifier)
```

Dispose the controller in your `State.dispose`.

## Customise

| Parameter | Default | What it does |
|---|---|---|
| `flipDuration` | 300 ms | Length of a full turn |
| `followFactor` | 0.22 | How fast the curl catches the finger each frame; lower feels heavier |
| `backsideOpacity` | 0.2 | How much of the page shows through its back |
| `paperColor` | white | Paper colour behind pages and on the back |
| `edgeTapFraction` | 0.2 | Width of the tap-to-turn zones |
| `enableDrag`, `enableTapToFlip` | true | Turn gestures on or off |
| `enableZoom` | true | Pinch and double tap zoom; one finger pans while zoomed |
| `maxScale` / `doubleTapScale` | 4 / 2.5 | Zoom limits |
| `onZoomChanged` | | Called when a zoom settles, e.g. to load a sharper image |

Night mode for PDFs:

```dart
PdfFlipBook.file(
  path,
  colorFilter: PdfFlipBook.nightMode,
  paperColor: const Color(0xFF1E1E1E),
)
```

Taps on the page edges turn pages at once. A tap in the middle waits a moment (double tap window) before calling `onCenterTap`, because a second tap there zooms.

`PdfFlipBook` also takes `loadingBuilder` (while the file opens), `placeholderBuilder` (a page before its first preview, plain paper by default), `pageErrorBuilder`, `errorBuilder` (the file could not be opened) and `password`.

## Which PDF engine

PDF pages are rendered with [pdfrx](https://pub.dev/packages/pdfrx) (MIT), which bundles Google's [PDFium](https://pdfium.googlesource.com/pdfium/), the engine inside Chrome.

- Renders in a background isolate, so turning stays smooth.
- Renders can be cancelled, so fast page turning does not queue up work.
- Handles encrypted PDFs, forms and annotations, on Android, iOS, macOS, Windows, Linux and web.
- Adds PDFium to your app, a few MB per platform. On iOS and macOS you can swap in Apple's own renderer with [pdfrx_coregraphics](https://pub.dev/packages/pdfrx_coregraphics) to save that space.

Only the pages near the current one are kept at full resolution (6 by default); small previews are kept for up to 60 pages.

## How the curl works

The fold line is the perpendicular bisector between the page corner and the finger. The part of the page beyond the line is cut away, and its mirror image across the line becomes the curled flap. The finger is kept within reach of the spine so the paper never tears off. While dragging, the curl eases towards the finger by `followFactor` each frame; after release it finishes with an ease-out sine over the remaining part of `flipDuration`.

## Example

`example/` has a demo app with a PDF tab (a small bundled sample PDF) and a widgets tab:

```sh
cd example
flutter run
```

## Not yet

- Right-to-left books (for example Arabic or Japanese)
- Two-page spreads on tablets

## License

MIT. See [LICENSE](LICENSE).
