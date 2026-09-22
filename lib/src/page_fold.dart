import 'package:flutter/widgets.dart';

class PageFold {
  const PageFold({
    required this.size,
    required this.foldPoint,
    required this.normal,
    required this.frontPath,
    required this.revealedPath,
    required this.flapPath,
    required this.reflection,
    required this.foldDistance,
    required this.progress,
  });

  final Size size;
  final Offset foldPoint;
  final Offset normal;
  final Path frontPath;
  final Path revealedPath;
  final Path flapPath;
  final Matrix4 reflection;
  final double foldDistance;
  final double progress;

  static PageFold? resolve({
    required Size size,
    required Offset corner,
    required Offset finger,
  }) {
    final pointer = clampToSpine(size: size, corner: corner, finger: finger);
    final delta = corner - pointer;
    final length = delta.distance;
    if (length < 0.5) return null;

    final normal = delta / length;
    final foldPoint = (corner + pointer) / 2;
    final pageCorners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];

    final front = clipPolygon(
      pageCorners,
      foldPoint,
      normal,
      keepCornerSide: false,
    );
    final lifted = clipPolygon(
      pageCorners,
      foldPoint,
      normal,
      keepCornerSide: true,
    );
    final flap = lifted.map((p) => reflect(p, foldPoint, normal)).toList();

    return PageFold(
      size: size,
      foldPoint: foldPoint,
      normal: normal,
      frontPath: polygonPath(front),
      revealedPath: polygonPath(lifted),
      flapPath: polygonPath(flap),
      reflection: reflectionMatrix(foldPoint, normal),
      foldDistance: length / 2,
      progress: ((corner.dx - pointer.dx) / (2 * size.width)).clamp(0.0, 1.0),
    );
  }

  static Offset clampToSpine({
    required Size size,
    required Offset corner,
    required Offset finger,
  }) {
    var point = Offset(finger.dx.clamp(-size.width, size.width), finger.dy);
    for (final spine in [Offset(0, size.height), Offset.zero]) {
      final radius = (corner - spine).distance;
      final offset = point - spine;
      if (offset.distance > radius) {
        point = spine + offset / offset.distance * radius;
      }
    }
    return point;
  }

  static List<Offset> clipPolygon(
    List<Offset> polygon,
    Offset foldPoint,
    Offset normal, {
    required bool keepCornerSide,
  }) {
    double side(Offset p) {
      final value =
          (p - foldPoint).dx * normal.dx + (p - foldPoint).dy * normal.dy;
      return keepCornerSide ? value : -value;
    }

    final result = <Offset>[];
    for (var i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final next = polygon[(i + 1) % polygon.length];
      final currentSide = side(current);
      final nextSide = side(next);
      if (currentSide >= 0) result.add(current);
      if ((currentSide >= 0) != (nextSide >= 0)) {
        final t = currentSide / (currentSide - nextSide);
        result.add(Offset.lerp(current, next, t) ?? current);
      }
    }
    return result;
  }

  static Offset reflect(Offset p, Offset foldPoint, Offset normal) {
    final d = (p - foldPoint).dx * normal.dx + (p - foldPoint).dy * normal.dy;
    return p - normal * (2 * d);
  }

  static Matrix4 reflectionMatrix(Offset foldPoint, Offset normal) {
    final nx = normal.dx;
    final ny = normal.dy;
    final c = 2 * (foldPoint.dx * nx + foldPoint.dy * ny);
    return Matrix4(
      1 - 2 * nx * nx,
      -2 * nx * ny,
      0,
      0,
      -2 * nx * ny,
      1 - 2 * ny * ny,
      0,
      0,
      0,
      0,
      1,
      0,
      c * nx,
      c * ny,
      0,
      1,
    );
  }

  static Path polygonPath(List<Offset> points) {
    final path = Path();
    if (points.length < 3) return path;
    path.addPolygon(points, true);
    return path;
  }
}
