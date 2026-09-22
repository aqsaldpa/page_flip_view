import 'dart:ui' as ui;

import 'page_fold.dart';
import 'page_fold_shading.dart';
import 'package:flutter/widgets.dart';

class PageFoldUnderPainter extends CustomPainter {
  const PageFoldUnderPainter(this.fold);

  final PageFold fold;

  static const double castWidth = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final shading = PageFoldShading(fold.progress, fold.foldDistance);
    final castEnd = fold.foldPoint + fold.normal * castWidth;

    canvas.save();
    canvas.clipPath(fold.revealedPath);
    canvas.drawPaint(
      Paint()
        ..shader = ui.Gradient.linear(fold.foldPoint, castEnd, [
          Color.fromRGBO(0, 0, 0, shading.underOpacity),
          const Color(0x00000000),
        ]),
    );
    canvas.restore();

    canvas.drawShadow(fold.flapPath, const Color(0xFF282828), 2, false);
  }

  @override
  bool shouldRepaint(PageFoldUnderPainter oldDelegate) =>
      oldDelegate.fold != fold;
}
