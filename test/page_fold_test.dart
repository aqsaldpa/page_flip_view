import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_flip_view/src/page_fold.dart';

void main() {
  const size = Size(390, 546);
  const corner = Offset(390, 546);

  test('no fold while the finger is on the corner', () {
    expect(
      PageFold.resolve(size: size, corner: corner, finger: corner),
      isNull,
    );
  });

  test('fold line is the perpendicular bisector of corner and finger', () {
    final fold = PageFold.resolve(
      size: size,
      corner: corner,
      finger: const Offset(0, 546),
    )!;
    expect(fold.foldPoint.dx, closeTo(195, 0.01));
    final mirrored = MatrixUtils.transformPoint(fold.reflection, corner);
    expect(mirrored.dx, closeTo(0, 0.01));
    expect(mirrored.dy, closeTo(546, 0.01));
  });

  test('finger is kept within reach of the spine', () {
    final clamped = PageFold.clampToSpine(
      size: size,
      corner: corner,
      finger: const Offset(-900, 1200),
    );
    expect(
      (clamped - const Offset(0, 546)).distance,
      lessThanOrEqualTo(390.01),
    );
  });
}
