import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../page_flip_view.dart';
import '../page_spread.dart';
import 'pdf_page_cache.dart';
import 'pdf_page_image.dart';

/// Builds what a page shows while its image is not rendered yet.
typedef PdfPagePlaceholderBuilder =
    Widget Function(BuildContext context, int pageIndex);

/// Builds what a page shows when rendering it failed.
typedef PdfPageErrorBuilder =
    Widget Function(BuildContext context, int pageIndex, VoidCallback retry);

/// Builds what is shown when the document could not be opened.
typedef PdfDocumentErrorBuilder =
    Widget Function(BuildContext context, Object error, VoidCallback retry);

/// Builds what is shown while the document opens. [progress] goes from 0 to
/// 1 while a [PdfFlipBook.network] file downloads, and is null when the
/// size is unknown or the source is local.
typedef PdfLoadingBuilder =
    Widget Function(BuildContext context, double? progress);

/// A PDF shown as a book with the corner-curl page turn of [PageFlipView].
///
/// Pages are rendered with [pdfrx](https://pub.dev/packages/pdfrx) (PDFium)
/// in a background isolate: a small preview appears at once, then the page
/// is sharpened to screen resolution. The pages around the current one are
/// rendered ahead of time, so turning pages does not show a spinner.
///
/// ```dart
/// PdfFlipBook.network(Uri.parse('https://example.com/book.pdf'))
/// PdfFlipBook.asset('assets/book.pdf')
/// PdfFlipBook.file('/path/book.pdf')
/// PdfFlipBook.data(bytes)
/// ```
class PdfFlipBook extends StatefulWidget {
  /// Downloads and opens the PDF at [uri]. Pass [headers] for authenticated
  /// URLs. The download progress is given to [loadingBuilder].
  const PdfFlipBook.network(
    Uri uri, {
    Key? key,
    Map<String, String>? headers,
    Duration? timeout,
    PageFlipController? controller,
    ValueChanged<int>? onPageChanged,
    ValueChanged<int>? onLoaded,
    VoidCallback? onCenterTap,
    Color paperColor = const Color(0xFFFFFFFF),
    PdfLoadingBuilder? loadingBuilder,
    PdfPagePlaceholderBuilder? placeholderBuilder,
    PdfPageErrorBuilder? pageErrorBuilder,
    PdfDocumentErrorBuilder? errorBuilder,
    String? password,
    ColorFilter? colorFilter,
    bool enableZoom = true,
    double maxScale = 4,
    PageSpreadMode spreadMode = PageSpreadMode.auto,
    bool coverAlone = true,
  }) : this._(
         key: key,
         uri: uri,
         headers: headers,
         timeout: timeout,
         controller: controller,
         onPageChanged: onPageChanged,
         onLoaded: onLoaded,
         onCenterTap: onCenterTap,
         paperColor: paperColor,
         loadingBuilder: loadingBuilder,
         placeholderBuilder: placeholderBuilder,
         pageErrorBuilder: pageErrorBuilder,
         errorBuilder: errorBuilder,
         password: password,
         colorFilter: colorFilter,
         enableZoom: enableZoom,
         maxScale: maxScale,
         spreadMode: spreadMode,
         coverAlone: coverAlone,
       );

  /// Opens the PDF at [path] on the device.
  const PdfFlipBook.file(
    String path, {
    Key? key,
    PageFlipController? controller,
    ValueChanged<int>? onPageChanged,
    ValueChanged<int>? onLoaded,
    VoidCallback? onCenterTap,
    Color paperColor = const Color(0xFFFFFFFF),
    PdfLoadingBuilder? loadingBuilder,
    PdfPagePlaceholderBuilder? placeholderBuilder,
    PdfPageErrorBuilder? pageErrorBuilder,
    PdfDocumentErrorBuilder? errorBuilder,
    String? password,
    ColorFilter? colorFilter,
    bool enableZoom = true,
    double maxScale = 4,
    PageSpreadMode spreadMode = PageSpreadMode.auto,
    bool coverAlone = true,
  }) : this._(
         key: key,
         filePath: path,
         controller: controller,
         onPageChanged: onPageChanged,
         onLoaded: onLoaded,
         onCenterTap: onCenterTap,
         paperColor: paperColor,
         loadingBuilder: loadingBuilder,
         placeholderBuilder: placeholderBuilder,
         pageErrorBuilder: pageErrorBuilder,
         errorBuilder: errorBuilder,
         password: password,
         colorFilter: colorFilter,
         enableZoom: enableZoom,
         maxScale: maxScale,
         spreadMode: spreadMode,
         coverAlone: coverAlone,
       );

  /// Opens the PDF bundled as the Flutter asset [name].
  const PdfFlipBook.asset(
    String name, {
    Key? key,
    PageFlipController? controller,
    ValueChanged<int>? onPageChanged,
    ValueChanged<int>? onLoaded,
    VoidCallback? onCenterTap,
    Color paperColor = const Color(0xFFFFFFFF),
    PdfLoadingBuilder? loadingBuilder,
    PdfPagePlaceholderBuilder? placeholderBuilder,
    PdfPageErrorBuilder? pageErrorBuilder,
    PdfDocumentErrorBuilder? errorBuilder,
    String? password,
    ColorFilter? colorFilter,
    bool enableZoom = true,
    double maxScale = 4,
    PageSpreadMode spreadMode = PageSpreadMode.auto,
    bool coverAlone = true,
  }) : this._(
         key: key,
         assetName: name,
         controller: controller,
         onPageChanged: onPageChanged,
         onLoaded: onLoaded,
         onCenterTap: onCenterTap,
         paperColor: paperColor,
         loadingBuilder: loadingBuilder,
         placeholderBuilder: placeholderBuilder,
         pageErrorBuilder: pageErrorBuilder,
         errorBuilder: errorBuilder,
         password: password,
         colorFilter: colorFilter,
         enableZoom: enableZoom,
         maxScale: maxScale,
         spreadMode: spreadMode,
         coverAlone: coverAlone,
       );

  /// Opens a PDF from memory, for example after downloading or decrypting it.
  const PdfFlipBook.data(
    Uint8List data, {
    Key? key,
    PageFlipController? controller,
    ValueChanged<int>? onPageChanged,
    ValueChanged<int>? onLoaded,
    VoidCallback? onCenterTap,
    Color paperColor = const Color(0xFFFFFFFF),
    PdfLoadingBuilder? loadingBuilder,
    PdfPagePlaceholderBuilder? placeholderBuilder,
    PdfPageErrorBuilder? pageErrorBuilder,
    PdfDocumentErrorBuilder? errorBuilder,
    String? password,
    ColorFilter? colorFilter,
    bool enableZoom = true,
    double maxScale = 4,
    PageSpreadMode spreadMode = PageSpreadMode.auto,
    bool coverAlone = true,
  }) : this._(
         key: key,
         bytes: data,
         controller: controller,
         onPageChanged: onPageChanged,
         onLoaded: onLoaded,
         onCenterTap: onCenterTap,
         paperColor: paperColor,
         loadingBuilder: loadingBuilder,
         placeholderBuilder: placeholderBuilder,
         pageErrorBuilder: pageErrorBuilder,
         errorBuilder: errorBuilder,
         password: password,
         colorFilter: colorFilter,
         enableZoom: enableZoom,
         maxScale: maxScale,
         spreadMode: spreadMode,
         coverAlone: coverAlone,
       );

  /// Shows a [PdfDocument] you already opened with pdfrx. The caller keeps
  /// ownership and disposes it.
  const PdfFlipBook.document(
    PdfDocument document, {
    Key? key,
    PageFlipController? controller,
    ValueChanged<int>? onPageChanged,
    ValueChanged<int>? onLoaded,
    VoidCallback? onCenterTap,
    Color paperColor = const Color(0xFFFFFFFF),
    PdfPagePlaceholderBuilder? placeholderBuilder,
    PdfPageErrorBuilder? pageErrorBuilder,
    ColorFilter? colorFilter,
    bool enableZoom = true,
    double maxScale = 4,
    PageSpreadMode spreadMode = PageSpreadMode.auto,
    bool coverAlone = true,
  }) : this._(
         key: key,
         document: document,
         controller: controller,
         onPageChanged: onPageChanged,
         onLoaded: onLoaded,
         onCenterTap: onCenterTap,
         paperColor: paperColor,
         placeholderBuilder: placeholderBuilder,
         pageErrorBuilder: pageErrorBuilder,
         colorFilter: colorFilter,
         enableZoom: enableZoom,
         maxScale: maxScale,
         spreadMode: spreadMode,
         coverAlone: coverAlone,
       );

  const PdfFlipBook._({
    super.key,
    String? filePath,
    String? assetName,
    Uint8List? bytes,
    Uri? uri,
    Map<String, String>? headers,
    Duration? timeout,
    PdfDocument? document,
    this.controller,
    this.onPageChanged,
    this.onLoaded,
    this.onCenterTap,
    this.paperColor = const Color(0xFFFFFFFF),
    this.loadingBuilder,
    this.placeholderBuilder,
    this.pageErrorBuilder,
    this.errorBuilder,
    this.password,
    this.colorFilter,
    this.enableZoom = true,
    this.maxScale = 4,
    this.spreadMode = PageSpreadMode.auto,
    this.coverAlone = true,
  }) : _filePath = filePath,
       _assetName = assetName,
       _bytes = bytes,
       _uri = uri,
       _headers = headers,
       _timeout = timeout,
       _document = document;

  /// A [colorFilter] that inverts every colour of the page: black text on
  /// white becomes light text on black.
  ///
  /// Covers, photos and illustrations are inverted too and look wrong, so
  /// use it only for text-only PDFs. Pair it with [nightPaper] as
  /// [paperColor]. For books with pictures prefer [dim], or keep the pages
  /// as they are and only darken the screen background.
  static const ColorFilter nightMode = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  /// A [colorFilter] that darkens the page to 75 % brightness and keeps
  /// every colour, so covers and pictures stay correct. Good for reading
  /// in a dark room. Pair it with [dimPaper] as [paperColor].
  static const ColorFilter dim = ColorFilter.matrix(<double>[
    0.75, 0, 0, 0, 0, //
    0, 0.75, 0, 0, 0, //
    0, 0, 0.75, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  /// A [colorFilter] that gives the page a warm, cream paper tone, easier on
  /// the eyes than bright white. Pictures keep their colours but look
  /// warmer. Pair it with [sepiaPaper] as [paperColor].
  static const ColorFilter sepia = ColorFilter.matrix(<double>[
    0.98, 0, 0, 0, 0, //
    0, 0.92, 0, 0, 0, //
    0, 0, 0.80, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  /// Paper colour for [dim]: white at 75 % brightness.
  static const Color dimPaper = Color(0xFFBFBFBF);

  /// Paper colour for [sepia]: white seen through the sepia filter.
  static const Color sepiaPaper = Color(0xFFFAEBCC);

  /// Paper colour for [nightMode]: white inverted.
  static const Color nightPaper = Color(0xFF000000);

  final String? _filePath;
  final String? _assetName;
  final Uint8List? _bytes;
  final Uri? _uri;
  final Map<String, String>? _headers;
  final Duration? _timeout;
  final PdfDocument? _document;

  /// Turns pages from code; see [PageFlipController].
  final PageFlipController? controller;

  /// Called with the zero-based page index after each turn or jump.
  final ValueChanged<int>? onPageChanged;

  /// Called once with the page count when the document is open.
  final ValueChanged<int>? onLoaded;

  /// Called on a tap in the middle of the page.
  final VoidCallback? onCenterTap;

  /// Colour of the paper: behind each page until it is rendered, and on the
  /// back of a turning sheet in single-page mode.
  ///
  /// Match it to how white looks on the page after [colorFilter]: white
  /// with no filter (also in a dark app theme), [dimPaper] with [dim],
  /// [sepiaPaper] with [sepia], [nightPaper] with [nightMode]. A mismatch
  /// shows as a wrong-coloured back while a page turns, for example a black
  /// flap on white pages.
  ///
  /// This is not the screen background around the book; set that on the
  /// parent (for example `Scaffold.backgroundColor`).
  final Color paperColor;

  /// Shown while the document opens or downloads. Defaults to a progress
  /// indicator that fills up while a network file downloads.
  final PdfLoadingBuilder? loadingBuilder;

  /// Shown on a page until its first preview is ready. Defaults to plain
  /// paper, which is usually only visible for a split second.
  final PdfPagePlaceholderBuilder? placeholderBuilder;

  /// Shown on a page whose rendering failed. Defaults to plain paper.
  final PdfPageErrorBuilder? pageErrorBuilder;

  /// Shown when the document cannot be opened. Defaults to a retry button.
  final PdfDocumentErrorBuilder? errorBuilder;

  /// Password for encrypted PDFs.
  final String? password;

  /// Colour filter applied to every rendered page.
  ///
  /// Ready-made: [dim] (darker, colours kept), [sepia] (warm tone) and
  /// [nightMode] (inverted, text-only books). Any [ColorFilter] works.
  final ColorFilter? colorFilter;

  /// Pinch or double tap to zoom into a page. The zoomed page is rendered
  /// again at the higher resolution, so text stays sharp.
  final bool enableZoom;

  /// Largest zoom factor.
  final double maxScale;

  /// One page, two pages side by side, or [PageSpreadMode.auto]: two pages
  /// when the space is wide (landscape, tablets, unfolded foldables such as
  /// the Galaxy Z Fold, where the spine lands on the fold). The book
  /// switches live when the device rotates or folds, keeping the page.
  final PageSpreadMode spreadMode;

  /// In two-page mode, whether the first page stands alone on the right,
  /// like the cover of a printed book.
  final bool coverAlone;

  bool _sameSource(PdfFlipBook other) =>
      other._filePath == _filePath &&
      other._assetName == _assetName &&
      other._bytes == _bytes &&
      other._uri == _uri &&
      other._document == _document;

  @override
  State<PdfFlipBook> createState() => _PdfFlipBookState();
}

class _PdfFlipBookState extends State<PdfFlipBook> {
  PdfDocument? _document;
  PdfPageCache? _cache;
  Object? _error;
  double? _progress;
  int _generation = 0;
  int _page = 0;
  bool _owned = true;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(PdfFlipBook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget._sameSource(oldWidget)) _reopen();
  }

  @override
  void dispose() {
    _generation++;
    _release();
    super.dispose();
  }

  void _release() {
    _cache?.dispose();
    _cache = null;
    if (_owned) _document?.dispose();
    _document = null;
  }

  void _reopen() {
    setState(() {
      _release();
      _error = null;
      _progress = null;
    });
    _open();
  }

  Future<PdfDocument> _load(int ticket) async {
    final given = widget._document;
    if (given != null) return given;
    await pdfrxFlutterInitialize();
    final password = widget.password;
    final provider = password == null ? null : () => password;
    final uri = widget._uri;
    if (uri != null) {
      return PdfDocument.openUri(
        uri,
        headers: widget._headers,
        timeout: widget._timeout,
        passwordProvider: provider,
        progressCallback: (received, [total]) {
          if (!mounted || ticket != _generation) return;
          final size = total ?? 0;
          setState(() => _progress = size > 0 ? received / size : null);
        },
      );
    }
    final path = widget._filePath;
    if (path != null) {
      return PdfDocument.openFile(path, passwordProvider: provider);
    }
    final asset = widget._assetName;
    if (asset != null) {
      return PdfDocument.openAsset(asset, passwordProvider: provider);
    }
    return PdfDocument.openData(
      widget._bytes ?? Uint8List(0),
      passwordProvider: provider,
    );
  }

  Future<void> _open() async {
    final ticket = ++_generation;
    final owned = widget._document == null;
    try {
      final opened = await _load(ticket);
      if (!mounted || ticket != _generation) {
        if (owned) await opened.dispose();
        return;
      }
      setState(() {
        _owned = owned;
        _document = opened;
        _page = widget.controller?.page ?? 0;
        _cache = PdfPageCache(document: opened)..prefetch(_page);
      });
      widget.onLoaded?.call(opened.pages.length);
    } catch (error) {
      if (!mounted || ticket != _generation) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return widget.errorBuilder?.call(context, error, _reopen) ??
          Center(
            child: IconButton(
              onPressed: _reopen,
              icon: const Icon(Icons.refresh),
            ),
          );
    }
    final cache = _cache;
    if (cache == null) {
      return widget.loadingBuilder?.call(context, _progress) ??
          Center(child: CircularProgressIndicator.adaptive(value: _progress));
    }
    if (cache.pageCount == 0) return const SizedBox.shrink();
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final aspect = cache.aspectRatioOf(0);
    return LayoutBuilder(
      builder: (context, outer) {
        final spread = switch (widget.spreadMode) {
          PageSpreadMode.single => false,
          PageSpreadMode.double => true,
          PageSpreadMode.auto => PageFlipView.shouldSpread(
            outer.biggest,
            aspect,
          ),
        };
        return Center(
          child: AspectRatio(
            aspectRatio: spread ? aspect * 2 : aspect,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pageSize = Size(
                  spread ? constraints.maxWidth / 2 : constraints.maxWidth,
                  constraints.maxHeight,
                );
                cache.resize(pageSize, devicePixelRatio);
                final layout = PageSpread(coverAlone: widget.coverAlone);
                return PageFlipView(
                  itemCount: cache.pageCount,
                  controller: widget.controller,
                  paperColor: widget.paperColor,
                  spread: spread,
                  coverAlone: widget.coverAlone,
                  onPageChanged: (page) {
                    _page = page;
                    cache.prefetch(page);
                    widget.onPageChanged?.call(page);
                  },
                  onCenterTap: widget.onCenterTap,
                  enableZoom: widget.enableZoom,
                  maxScale: widget.maxScale,
                  onZoomChanged: (scale) {
                    final visible = spread
                        ? [
                            layout.leftOf(layout.spreadOf(_page)),
                            layout.rightOf(layout.spreadOf(_page)),
                          ]
                        : [_page];
                    cache.zoom(visible, scale);
                  },
                  itemBuilder: (context, index) => PdfPageImage(
                    cache: cache,
                    index: index,
                    paperColor: widget.paperColor,
                    placeholderBuilder: widget.placeholderBuilder,
                    pageErrorBuilder: widget.pageErrorBuilder,
                    colorFilter: widget.colorFilter,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
