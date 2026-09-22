class PageFoldShading {
  const PageFoldShading(this.progress, this.foldDistance);

  final double progress;
  final double foldDistance;

  static const double fullShadowDistance = 260;

  double get envelope {
    if (progress > 0.9) return (1 - progress) / 0.1;
    if (progress < 0.1) return progress / 0.1;
    return 1;
  }

  double get reach => (foldDistance / fullShadowDistance).clamp(0.0, 1.0);

  double get frontOpacity =>
      foldDistance > fullShadowDistance ? 0.34 * envelope : 0.34 * reach;

  double get underOpacity => 0.3 * envelope;

  double get edgeOpacity => 0.5 * envelope;

  double get highlightOpacity => 0.34 * envelope;
}
