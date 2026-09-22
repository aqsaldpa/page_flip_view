import 'dart:ui' as ui;

import 'page_fold.dart';
import 'page_fold_shading.dart';
import 'package:flutter/widgets.dart';

class PageFoldFlapPainter extends CustomPainter {
  const PageFoldFlapPainter(this.fold);

  final PageFold fold;

  static const double shadeWidth = 173;
  static const double highlightWidth = 78;
  static const double edgeWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final shading = PageFoldShading(fold.progress, fold.foldDistance);
    final inward = -fold.normal;
    final reach = shading.reach;
    final origin = fold.foldPoint;

    canvas.save();
    canvas.clipPath(fold.flapPath);

    paintBand(canvas, origin, origin + inward * (shadeWidth * reach), [
      Color.fromRGBO(103, 102, 102, shading.frontOpacity),
      const Color(0x00696969),
    ]);

    final highlightStart = origin + inward * (8 * reach);
    paintBand(
      canvas,
      highlightStart,
      highlightStart + inward * (highlightWidth * reach),
      [
        const Color(0x00FFFFFF),
        Color.fromRGBO(255, 255, 255, shading.highlightOpacity),
        const Color(0x00FFFFFF),
      ],
      const [0, 0.5, 1],
    );

    paintBand(canvas, origin, origin + inward * edgeWidth, [
      Color.fromRGBO(19, 19, 19, 0.44 * shading.edgeOpacity),
      const Color(0x00131313),
    ]);

    canvas.restore();
  }

  void paintBand(
    Canvas canvas,
    Offset from,
    Offset to,
    List<Color> colors, [
    List<double>? stops,
  ]) {
    if ((to - from).distanceSquared < 1) return;
    canvas.drawPaint(
      Paint()..shader = ui.Gradient.linear(from, to, colors, stops),
    );
  }

  @override
  bool shouldRepaint(PageFoldFlapPainter oldDelegate) =>
      oldDelegate.fold != fold;
}
