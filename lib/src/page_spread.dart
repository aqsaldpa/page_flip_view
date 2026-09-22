/// How pages are laid out: one at a time, or two side by side like an open
/// book.
enum PageSpreadMode {
  /// Two pages when the space is wide enough (landscape phones, tablets,
  /// unfolded foldables), otherwise one.
  auto,

  /// Always one page.
  single,

  /// Always two pages side by side.
  double,
}

class PageSpread {
  const PageSpread({required this.coverAlone});

  final bool coverAlone;

  static bool fits(double width, double height, double pageAspectRatio) =>
      height > 0 && width / height >= pageAspectRatio * 1.6;

  int spreadOf(int page) => coverAlone ? (page + 1) ~/ 2 : page ~/ 2;

  int leftOf(int spread) => coverAlone ? 2 * spread - 1 : 2 * spread;

  int rightOf(int spread) => leftOf(spread) + 1;
}
