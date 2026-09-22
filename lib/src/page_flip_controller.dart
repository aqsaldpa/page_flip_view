part of 'page_flip_view.dart';

/// Drives a [PageFlipView] from outside: turn pages with an animation,
/// jump without one, and listen for the current page.
///
/// ```dart
/// final controller = PageFlipController();
/// PageFlipView(controller: controller, itemCount: 10, itemBuilder: ...);
/// controller.next();
/// ```
class PageFlipController extends ChangeNotifier {
  /// Creates a controller that starts on [initialPage] (zero based).
  PageFlipController({int initialPage = 0}) : _page = initialPage;

  int _page;
  _PageFlipViewState? _state;

  /// The page currently shown, zero based.
  int get page => _page;

  /// Whether a [PageFlipView] is using this controller.
  bool get isAttached => _state != null;

  /// Turns to the next page with the curl animation.
  /// Completes when the animation ends; does nothing on the last page.
  Future<void> next() => _state?._autoTurn(forward: true) ?? Future.value();

  /// Turns back to the previous page with the curl animation.
  Future<void> previous() =>
      _state?._autoTurn(forward: false) ?? Future.value();

  /// Shows [page] immediately, without animation.
  void jumpTo(int page) {
    if (page == _page) return;
    _page = page;
    _state?._jumpTo(page);
    notifyListeners();
  }

  void _settle(int page) {
    if (page == _page) return;
    _page = page;
    notifyListeners();
  }
}
