import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../page_flip_view.dart';
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

/// A PDF shown as a book with the corner-curl page turn of [PageFlipView].
///
/// Pages are rendered with [pdfrx](https://pub.dev/packages/pdfrx) (PDFium)
/// in a background isolate: a small preview appears at once, then the page
/// is sharpened to screen resolution. The pages around the current one are
/// rendered ahead of time, so turning pages does not show a spinner.
///
/// ```dart
/// PdfFlipBook.file('/path/book.pdf')
/// PdfFlipBook.asset('assets/book.pdf')
/// PdfFlipBook.data(bytes)
/// ```
class PdfFlipBook extends StatefulWidget {
  /// Opens the PDF at [path] on the device.
  const PdfFlipBook.file(
    String path, {
    Key? key,
    PageFlipController? controller,
    ValueChanged<int>? onPageChanged,
    ValueChanged<int>? onLoaded,
    VoidCallback? onCenterTap,
    Color paperColor = const Color(0xFFFFFFFF),
    WidgetBuilder? loadingBuilder,
    PdfPagePlaceholderBuilder? placeholderBuilder,
    PdfPageErrorBuilder? pageErrorBuilder,
    PdfDocumentErrorBuilder? errorBuilder,
    String? password,
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
    WidgetBuilder? loadingBuilder,
    PdfPagePlaceholderBuilder? placeholderBuilder,
    PdfPageErrorBuilder? pageErrorBuilder,
    PdfDocumentErrorBuilder? errorBuilder,
    String? password,
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
    WidgetBuilder? loadingBuilder,
    PdfPagePlaceholderBuilder? placeholderBuilder,
    PdfPageErrorBuilder? pageErrorBuilder,
    PdfDocumentErrorBuilder? errorBuilder,
    String? password,
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
  }) : this._(
         key: key,
         openedDocument: document,
         controller: controller,
         onPageChanged: onPageChanged,
         onLoaded: onLoaded,
         onCenterTap: onCenterTap,
         paperColor: paperColor,
         placeholderBuilder: placeholderBuilder,
         pageErrorBuilder: pageErrorBuilder,
       );

  const PdfFlipBook._({
    super.key,
    this.filePath,
    this.assetName,
    this.bytes,
    this.openedDocument,
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
  });

  final String? filePath;
  final String? assetName;
  final Uint8List? bytes;
  final PdfDocument? openedDocument;

  /// Turns pages from code; see [PageFlipController].
  final PageFlipController? controller;

  /// Called with the zero-based page index after each turn or jump.
  final ValueChanged<int>? onPageChanged;

  /// Called once with the page count when the document is open.
  final ValueChanged<int>? onLoaded;

  /// Called on a tap in the middle of the page.
  final VoidCallback? onCenterTap;

  /// Paper colour behind pages and on the back of a turning page.
  final Color paperColor;

  /// Shown while the document opens. Defaults to a small progress indicator.
  final WidgetBuilder? loadingBuilder;

  /// Shown on a page until its first preview is ready. Defaults to plain
  /// paper, which is usually only visible for a split second.
  final PdfPagePlaceholderBuilder? placeholderBuilder;

  /// Shown on a page whose rendering failed. Defaults to plain paper.
  final PdfPageErrorBuilder? pageErrorBuilder;

  /// Shown when the document cannot be opened. Defaults to a retry button.
  final PdfDocumentErrorBuilder? errorBuilder;

  /// Password for encrypted PDFs.
  final String? password;

  @override
  State<PdfFlipBook> createState() => _PdfFlipBookState();
}

class _PdfFlipBookState extends State<PdfFlipBook> {
  PdfDocument? _document;
  PdfPageCache? _cache;
  Object? _error;
  int _generation = 0;

  bool get _ownsDocument => widget.openedDocument == null;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(PdfFlipBook oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sourceChanged =
        oldWidget.filePath != widget.filePath ||
        oldWidget.assetName != widget.assetName ||
        oldWidget.bytes != widget.bytes ||
        oldWidget.openedDocument != widget.openedDocument;
    if (sourceChanged) _reopen();
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
    if (_ownsDocument) _document?.dispose();
    _document = null;
  }

  void _reopen() {
    setState(() {
      _release();
      _error = null;
    });
    _open();
  }

  Future<PdfDocument> _load() async {
    final given = widget.openedDocument;
    if (given != null) return given;
    await pdfrxFlutterInitialize();
    final password = widget.password;
    final provider = password == null ? null : () => password;
    final path = widget.filePath;
    if (path != null) {
      return PdfDocument.openFile(path, passwordProvider: provider);
    }
    final asset = widget.assetName;
    if (asset != null) {
      return PdfDocument.openAsset(asset, passwordProvider: provider);
    }
    return PdfDocument.openData(
      widget.bytes ?? Uint8List(0),
      passwordProvider: provider,
    );
  }

  Future<void> _open() async {
    final ticket = ++_generation;
    try {
      final opened = await _load();
      if (!mounted || ticket != _generation) {
        if (_ownsDocument) await opened.dispose();
        return;
      }
      setState(() {
        _document = opened;
        _cache = PdfPageCache(document: opened)
          ..prefetch(widget.controller?.page ?? 0);
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
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator.adaptive());
    }
    if (cache.pageCount == 0) return const SizedBox.shrink();
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Center(
      child: AspectRatio(
        aspectRatio: cache.aspectRatioOf(0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            cache.resize(constraints.biggest, devicePixelRatio);
            return PageFlipView(
              itemCount: cache.pageCount,
              controller: widget.controller,
              paperColor: widget.paperColor,
              onPageChanged: (page) {
                cache.prefetch(page);
                widget.onPageChanged?.call(page);
              },
              onCenterTap: widget.onCenterTap,
              itemBuilder: (context, index) => PdfPageImage(
                cache: cache,
                index: index,
                paperColor: widget.paperColor,
                placeholderBuilder: widget.placeholderBuilder,
                pageErrorBuilder: widget.pageErrorBuilder,
              ),
            );
          },
        ),
      ),
    );
  }
}
