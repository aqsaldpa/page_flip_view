# page_flip_view

[![pub package](https://img.shields.io/pub/v/page_flip_view.svg)](https://pub.dev/packages/page_flip_view)

<p align="center"><img src="https://raw.githubusercontent.com/aqsaldpa/page_flip_view/main/doc/demo.gif" width="300" alt="A PDF page being turned with a diagonal corner curl"></p>

| Two pages on wide screens | Pinch and double tap zoom |
|:---:|:---:|
| <img src="https://raw.githubusercontent.com/aqsaldpa/page_flip_view/main/doc/spread.gif" width="320" alt="Two-page spread turning"> | <img src="https://raw.githubusercontent.com/aqsaldpa/page_flip_view/main/doc/zoom.gif" width="180" alt="Double tap zoom and pan"> |

<p align="center"><img src="https://raw.githubusercontent.com/aqsaldpa/page_flip_view/main/doc/reading_modes.png" width="640" alt="Reading modes: normal, dim, sepia, night"><br><sub>Reading modes: normal, dim, sepia, night</sub></p>

Turn pages like a real book or magazine. The page corner lifts diagonally, follows your finger, and falls back or turns over when you let go. Use it for PDF books, magazines, catalogues, comics, or any list of widgets.

## Features

- Diagonal corner curl that tracks the finger (top or bottom corner, whichever you grab)
- Release past the middle or fling to turn; otherwise the page falls back
- Tap the page edges to turn; tap the middle for your own action (show a toolbar, for example)
- The back of the turning page shows the page faintly through the paper, with soft fold shadows
- Two pages side by side like an open book on landscape phones, tablets and unfolded foldables, switching live when the device rotates or folds
- Pinch or double tap to zoom; PDF pages are re-rendered sharp at the zoom level
- PDF from a URL, a file, an asset or bytes, with download progress and passwords
- Reading modes for PDFs: dim, sepia and night, each with a matching paper colour
- No spinner while turning PDF pages: a small preview appears at once and sharpens a moment later
- `PageFlipController` for previous / next / jump from buttons or sliders

## Getting started

**1. Add the package**

```sh
flutter pub add page_flip_view
```

or in `pubspec.yaml`:

```yaml
dependencies:
  page_flip_view: ^0.4.1
```

**2. Platform setup** (only needed for PDFs)

- **iOS**: iOS 15 or newer. In `ios/Podfile` set `platform :ios, '15.0'`, then run `pod install` in `ios/`.
- **Android**: nothing to do for local PDFs. For `PdfFlipBook.network`, make sure `android/app/src/main/AndroidManifest.xml` has `<uses-permission android:name="android.permission.INTERNET" />` (Flutter only adds it to debug builds).
- **macOS**: macOS 12 or newer; for network PDFs enable *Outgoing Connections (Client)* in the app sandbox.

**3. Show a book**

```dart
import 'package:page_flip_view/pdf.dart';

class BookScreen extends StatelessWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade800,
      body: SafeArea(
        child: PdfFlipBook.network(
          Uri.parse('https://example.com/book.pdf'),
        ),
      ),
    );
  }
}
```

That is all. Opening, downloading, rendering, caching and cleanup are handled for you.

## Open a PDF from anywhere

```dart
PdfFlipBook.network(Uri.parse(url), headers: {'Authorization': 'Bearer $token'})
PdfFlipBook.file('/path/to/book.pdf')       // a file on the device
PdfFlipBook.asset('assets/book.pdf')        // bundled with the app (list it under flutter/assets)
PdfFlipBook.data(bytes)                     // after downloading or decrypting yourself
PdfFlipBook.document(pdfDocument)           // a pdfrx PdfDocument you opened yourself
```

Every constructor takes `password` for encrypted files.

## Any widgets as pages

```dart
import 'package:page_flip_view/page_flip_view.dart';

PageFlipView(
  itemCount: photos.length,
  itemBuilder: (context, index) => Image.network(photos[index], fit: BoxFit.cover),
)
```

Only the current page and the pages taking part in a turn are built.

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

## Tablets and foldables

`PdfFlipBook` picks the layout by itself (`spreadMode: PageSpreadMode.auto`):

| Screen | Layout |
|---|---|
| Phone, or foldable folded (cover screen) | One page |
| Foldable unfolded and held upright (Galaxy Z Fold, Pixel Fold) | One large page: the screen is almost square, so two pages would each be too small |
| Landscape phone, tablet, foldable unfolded sideways | Two pages like an open book; the spine sits in the middle, on the fold |

When the device rotates, folds or unfolds, the book switches layout on the fly and stays on the same page. A turn in progress is cancelled cleanly.

Force a layout with `spreadMode: PageSpreadMode.single` or `PageSpreadMode.double`. In two-page mode the first page stands alone on the right, like a book cover; turn that off with `coverAlone: false`.

For your own widgets:

```dart
LayoutBuilder(builder: (context, box) {
  final spread = PageFlipView.shouldSpread(box.biggest, pageAspectRatio);
  return AspectRatio(
    aspectRatio: spread ? pageAspectRatio * 2 : pageAspectRatio,
    child: PageFlipView(spread: spread, itemCount: n, itemBuilder: buildPage),
  );
})
```

## Reading modes (dim, sepia, night)

`PdfFlipBook` can pass every page through a colour filter. Each ready-made filter comes with the paper colour that matches it:

| Mode | `colorFilter` | `paperColor` | Colours of covers and pictures | Use for |
|---|---|---|---|---|
| Normal | none | white (default) | unchanged | everything |
| Dim | `PdfFlipBook.dim` | `PdfFlipBook.dimPaper` | kept, 75 % brightness | reading in a dark room, any book |
| Sepia | `PdfFlipBook.sepia` | `PdfFlipBook.sepiaPaper` | kept, warmer tone | long reading on cream paper |
| Night | `PdfFlipBook.nightMode` | `PdfFlipBook.nightPaper` | **inverted**: they look wrong | text-only books |

```dart
PdfFlipBook.file(
  path,
  colorFilter: PdfFlipBook.dim,
  paperColor: PdfFlipBook.dimPaper,
)
```

Three things to get right:

1. **`paperColor` is the paper, not the screen background.** It shows behind a page until the page is rendered, and on the back of a turning sheet in single-page mode (in two-page mode the back shows the next page). The area around the book is your own widget, for example `Scaffold(backgroundColor: ...)`.
2. **Always change `colorFilter` and `paperColor` together**, using the pairs above. If they do not match, the back of a turning page shows the wrong colour, for example a black flap on white pages.
3. **A dark app theme does not need a filter.** To keep books exactly as printed, darken only the screen background and leave `colorFilter` null and `paperColor` white.

## Loading, placeholders and errors

```dart
PdfFlipBook.network(
  uri,
  loadingBuilder: (context, progress) => LinearProgressIndicator(value: progress),
  errorBuilder: (context, error, retry) => TextButton(onPressed: retry, child: const Text('Retry')),
  placeholderBuilder: (context, page) => const ColoredBox(color: Colors.white),
  pageErrorBuilder: (context, page, retry) => IconButton(onPressed: retry, icon: const Icon(Icons.refresh)),
)
```

`progress` goes from 0 to 1 while a network PDF downloads, and is `null` when the size is unknown.

## All options

`PageFlipView` and `PdfFlipBook`:

| Parameter | Default | What it does |
|---|---|---|
| `controller` | | Turn pages from code |
| `onPageChanged` | | Called with the page index after a turn or jump |
| `onCenterTap` | | Tap in the middle of the page |
| `paperColor` | white | The paper: behind unrendered pages and on the back of a turning sheet in single-page mode (not the screen background) |
| `enableZoom` | true | Pinch and double tap zoom; one finger pans while zoomed |
| `maxScale` | 4 | Largest zoom factor |
| `coverAlone` | true | In two-page mode, the first page stands alone on the right |

`PageFlipView` only:

| Parameter | Default | What it does |
|---|---|---|
| `itemCount`, `itemBuilder` | required | The pages |
| `initialPage` | 0 | First page when no controller is given |
| `flipDuration` | 300 ms | Length of a full turn |
| `followFactor` | 0.22 | How fast the curl catches the finger; lower feels heavier |
| `backsideOpacity` | 0.2 | How much of the page shows through its back |
| `edgeTapFraction` | 0.2 | Width of the tap-to-turn zones |
| `enableDrag`, `enableTapToFlip` | true | Turn gestures on or off |
| `doubleTapScale` | 2.5 | Zoom factor of a double tap |
| `onZoomChanged` | | Called when a zoom settles, e.g. to load a sharper image |
| `spread` | false | Two pages side by side; give the view twice a page's width |

`PdfFlipBook` only: `spreadMode` (auto / single / double), `colorFilter` (see reading modes), `onLoaded`, `loadingBuilder`, `placeholderBuilder`, `pageErrorBuilder`, `errorBuilder`, `password`, and `headers` / `timeout` for `.network`.

Taps on the page edges turn pages at once. A tap in the middle waits a moment (the double tap window) before calling `onCenterTap`, because a second tap there zooms.

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

[`example/`](example) has three tabs: a bundled PDF with a reading mode switch (normal, dim, sepia, night), a PDF downloaded from a URL, and plain widgets.

```sh
cd example
flutter run
```

## Not yet

- Right-to-left books (for example Arabic or Japanese)
- Dual-screen devices with a physical hinge gap (Surface Duo): the spine is centred, not moved around the gap

## License

MIT. See [LICENSE](LICENSE).
