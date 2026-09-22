import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';

/// Renders PDF pages to images around the current page.
///
/// Each page is first rendered as a small preview (fast, shown at once),
/// then at full screen resolution. Previews are kept for many pages;
/// full images only for the pages near the current one.
class PdfPageCache extends ChangeNotifier {
  PdfPageCache({
    required this.document,
    this.fullCapacity = 6,
    this.previewCapacity = 60,
    this.maxPixelSide = 2048,
    this.previewPixelSide = 360,
    this.prefetchRadius = 2,
  });

  final PdfDocument document;
  final int fullCapacity;
  final int previewCapacity;
  final int maxPixelSide;
  final int previewPixelSide;
  final int prefetchRadius;

  final LinkedHashMap<int, ui.Image> _full = LinkedHashMap();
  final LinkedHashMap<int, ui.Image> _preview = LinkedHashMap();
  final Map<int, Size> _fullSize = {};
  final Map<String, PdfPageRenderCancellationToken> _pending = {};
  final Set<int> _failed = {};
  Size _pixelSize = Size.zero;
  int _center = 0;
  bool _disposed = false;

  int get pageCount => document.pages.length;

  double aspectRatioOf(int index) {
    final page = document.pages[index];
    return page.height == 0 ? 1 : page.width / page.height;
  }

  ui.Image? imageAt(int index) => _full[index] ?? _preview[index];

  bool hasFailed(int index) => _failed.contains(index);

  void resize(Size logicalSize, double devicePixelRatio) {
    final next = logicalSize * devicePixelRatio;
    if ((next.width - _pixelSize.width).abs() < 1 &&
        (next.height - _pixelSize.height).abs() < 1) {
      return;
    }
    _pixelSize = next;
    prefetch(_center);
  }

  void prefetch(int center) {
    _center = center;
    if (_pixelSize.isEmpty) return;
    final window = [
      center,
      for (var d = 1; d <= prefetchRadius; d++) ...[center + d, center - d],
    ].where((i) => i >= 0 && i < pageCount).toList();
    _cancelOutside(window);
    for (final index in window) {
      _render(index, preview: true);
    }
    for (final index in window) {
      _render(index, preview: false);
    }
    _evict();
  }

  void retry(int index) {
    _failed.remove(index);
    _render(index, preview: true);
    _render(index, preview: false);
  }

  Future<void> _render(int index, {required bool preview}) async {
    final key = '${preview ? 'p' : 'f'}$index';
    if (_pending.containsKey(key)) return;
    if (preview && _preview.containsKey(index)) return;
    if (!preview && _fullSize[index] == _pixelSize) return;

    final page = document.pages[index];
    final longest = math.max(page.width, page.height);
    final scale = preview
        ? previewPixelSide / longest
        : math.min(
            maxPixelSide / longest,
            math.min(
              _pixelSize.width / page.width,
              _pixelSize.height / page.height,
            ),
          );
    final target = _pixelSize;
    final token = page.createCancellationToken();
    _pending[key] = token;
    try {
      final rendered = await page.render(
        width: (page.width * scale).round(),
        height: (page.height * scale).round(),
        fullWidth: page.width * scale,
        fullHeight: page.height * scale,
        backgroundColor: 0xffffffff,
        cancellationToken: token,
      );
      if (rendered == null) return;
      final image = await rendered.createImage();
      rendered.dispose();
      if (_disposed || _pending[key] != token) {
        image.dispose();
        return;
      }
      if (preview) {
        _preview.remove(index)?.dispose();
        _preview[index] = image;
      } else {
        _full.remove(index)?.dispose();
        _full[index] = image;
        _fullSize[index] = target;
      }
      _failed.remove(index);
    } catch (_) {
      if (!preview) _failed.add(index);
    } finally {
      if (_pending[key] == token) _pending.remove(key);
      if (!_disposed) notifyListeners();
    }
  }

  void _cancelOutside(List<int> window) {
    final keep = {
      for (final i in window) ...['p$i', 'f$i'],
    };
    for (final key in _pending.keys.toList()) {
      if (keep.contains(key)) continue;
      _pending.remove(key)?.cancel();
    }
  }

  void _evict() {
    _evictFrom(_full, fullCapacity, onEvict: _fullSize.remove);
    _evictFrom(_preview, previewCapacity);
  }

  void _evictFrom(
    LinkedHashMap<int, ui.Image> images,
    int capacity, {
    void Function(int)? onEvict,
  }) {
    while (images.length > capacity) {
      final farthest = images.keys.reduce(
        (a, b) => (a - _center).abs() >= (b - _center).abs() ? a : b,
      );
      images.remove(farthest)?.dispose();
      onEvict?.call(farthest);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final token in _pending.values) {
      token.cancel();
    }
    _pending.clear();
    for (final image in [..._full.values, ..._preview.values]) {
      image.dispose();
    }
    _full.clear();
    _preview.clear();
    super.dispose();
  }
}
