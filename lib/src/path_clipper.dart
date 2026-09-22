import 'package:flutter/widgets.dart';

class PathClipper extends CustomClipper<Path> {
  const PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(PathClipper oldClipper) => oldClipper.path != path;
}
