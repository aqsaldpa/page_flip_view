import 'package:flutter/widgets.dart';

class PageTurn {
  const PageTurn({
    required this.index,
    required this.corner,
    required this.forward,
  });

  final int index;
  final Offset corner;
  final bool forward;

  Offset restingPoint(Size size) =>
      forward ? corner : Offset(-size.width, corner.dy);

  Offset turnedPoint(Size size) =>
      forward ? Offset(-size.width, corner.dy) : corner;

  bool isBottomCorner(Size size) => corner.dy > size.height / 2;
}
