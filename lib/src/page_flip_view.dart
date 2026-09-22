import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'page_fold.dart';
import 'page_fold_flap_painter.dart';
import 'page_fold_under_painter.dart';
import 'page_turn.dart';
import 'path_clipper.dart';

part 'page_flip_controller.dart';

/// A book-like pager: pages turn with a diagonal corner curl that follows
/// the finger, like a printed magazine.
///
/// Pages are ordinary widgets, so any content works: images, PDF pages
/// (see `package:page_flip_view/pdf.dart`), or layouts.
///
/// Gestures:
/// * drag horizontally anywhere on the page; the corner nearest the touch
///   (top or bottom) lifts and follows the finger;
/// * release past the middle, or fling, to finish the turn; otherwise the
///   page falls back;
/// * tap the outer [edgeTapFraction] of the page to turn; tap the middle to
///   get [onCenterTap] (typically to show reader controls).
class PageFlipView extends StatefulWidget {
  /// Creates a flip view with [itemCount] pages built lazily by [itemBuilder].
  ///
  /// Only the current page and its neighbours are built at any time.
  const PageFlipView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.initialPage = 0,
    this.onPageChanged,
    this.onCenterTap,
    this.enableDrag = true,
    this.enableTapToFlip = true,
    this.paperColor = const Color(0xFFFFFFFF),
    this.backsideOpacity = 0.2,
    this.flipDuration = const Duration(milliseconds: 300),
    this.followFactor = 0.22,
    this.edgeTapFraction = 0.2,
  });

  /// Number of pages.
  final int itemCount;

  /// Builds page [index]. Called for the visible page and the pages taking
  /// part in a turn.
  final IndexedWidgetBuilder itemBuilder;

  /// Optional controller for turning pages from code.
  final PageFlipController? controller;

  /// First page to show when no [controller] is given.
  final int initialPage;

  /// Called after a turn completes or after [PageFlipController.jumpTo].
  final ValueChanged<int>? onPageChanged;

  /// Called on a tap in the middle area of the page.
  final VoidCallback? onCenterTap;

  /// Whether dragging turns pages.
  final bool enableDrag;

  /// Whether tapping the page edges turns pages.
  final bool enableTapToFlip;

  /// Colour of the paper seen on the back of a turning page.
  final Color paperColor;

  /// How much of the page shows through its back, from 0 (plain paper)
  /// to 1 (a full mirrored copy).
  final double backsideOpacity;

  /// Duration of a full turn. Partial turns finishing after a drag use the
  /// remaining fraction of it.
  final Duration flipDuration;

  /// How quickly the curl catches up with the finger each frame, from 0 to 1.
  /// Lower values feel heavier.
  final double followFactor;

  /// Width of the tap-to-turn zones at the left and right edges, as a
  /// fraction of the page width.
  final double edgeTapFraction;

  @override
  State<PageFlipView> createState() => _PageFlipViewState();
}

class _PageFlipViewState extends State<PageFlipView>
    with TickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);
  late final Ticker _follow = createTicker(_onFollowTick);

  late int _page = widget.controller?.page ?? widget.initialPage;
  PageTurn? _turn;
  Size _size = Size.zero;
  Offset _shown = Offset.zero;
  Offset _target = Offset.zero;
  Offset _dragStart = Offset.zero;
  Duration _lastTick = Duration.zero;
  Offset Function(double)? _motionPath;

  bool get _busy => _motion.isAnimating;

  @override
  void initState() {
    super.initState();
    _motion.addListener(_onMotionTick);
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(PageFlipView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller?._state = null;
      }
      widget.controller?._state = this;
    }
    if (_page >= widget.itemCount && widget.itemCount > 0) {
      _page = widget.itemCount - 1;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _follow.dispose();
    _motion.dispose();
    super.dispose();
  }

  void _jumpTo(int page) {
    _follow.stop();
    _motion.stop();
    setState(() {
      _turn = null;
      _page = page.clamp(0, math.max(0, widget.itemCount - 1));
    });
    widget.onPageChanged?.call(_page);
  }

  bool _canTurn({required bool forward}) =>
      forward ? _page < widget.itemCount - 1 : _page > 0;

  PageTurn _beginTurn({required bool forward, required double touchY}) {
    final corner = Offset(
      _size.width,
      touchY > _size.height / 2 ? _size.height : 0,
    );
    return PageTurn(
      index: forward ? _page : _page - 1,
      corner: corner,
      forward: forward,
    );
  }

  void _onDragStart(DragStartDetails details) {
    if (_busy) return;
    _dragStart = details.localPosition;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_busy) return;
    final delta = details.localPosition - _dragStart;
    var active = _turn;
    if (active == null) {
      if (delta.dx.abs() < 4) return;
      final forward = delta.dx < 0;
      if (!_canTurn(forward: forward)) return;
      active = _beginTurn(forward: forward, touchY: _dragStart.dy);
      _shown = active.restingPoint(_size);
      setState(() => _turn = active);
    }
    final gain = active.forward ? 1.0 : 2.0;
    _target = active.restingPoint(_size) + Offset(delta.dx * gain, delta.dy);
    if (!_follow.isActive) {
      _lastTick = Duration.zero;
      _follow.start();
    }
  }

  void _onFollowTick(Duration elapsed) {
    final frames = _lastTick == Duration.zero
        ? 1.0
        : (elapsed - _lastTick).inMicroseconds / 16667;
    _lastTick = elapsed;
    final alpha = 1 - math.pow(1 - widget.followFactor, frames).toDouble();
    setState(() => _shown = Offset.lerp(_shown, _target, alpha) ?? _target);
  }

  void _onDragEnd(DragEndDetails details) {
    final active = _turn;
    if (active == null || _busy) return;
    _follow.stop();
    final velocity = details.velocity.pixelsPerSecond.dx;
    final commit = active.forward
        ? velocity < -250 || (velocity <= 250 && _target.dx < _size.width / 2)
        : velocity > 250 || (velocity >= -250 && _target.dx > 0);
    final end = commit ? active.turnedPoint(_size) : active.restingPoint(_size);
    final start = _shown;
    final fraction = ((end.dx - start.dx).abs() / (2 * _size.width)).clamp(
      0.2,
      1.0,
    );
    _runMotion(
      duration: widget.flipDuration * fraction,
      curve: Curves.easeOutSine,
      path: (t) => Offset.lerp(start, end, t) ?? end,
      onDone: () => _finishTurn(active, committed: commit),
    );
  }

  Future<void> _autoTurn({required bool forward}) {
    if (_busy ||
        _turn != null ||
        _size.isEmpty ||
        !_canTurn(forward: forward)) {
      return Future.value();
    }
    final active = _beginTurn(forward: forward, touchY: _size.height);
    final start = active.restingPoint(_size);
    final end = active.turnedPoint(_size);
    final width = _size.width;
    setState(() {
      _turn = active;
      _shown = start;
    });
    return _runMotion(
      duration: widget.flipDuration,
      curve: Curves.easeInOutSine,
      path: (t) {
        final x = start.dx + (end.dx - start.dx) * t;
        final lift = 0.05 * math.sqrt(math.max(0, width * width - x * x));
        return Offset(x, active.corner.dy - lift);
      },
      onDone: () => _finishTurn(active, committed: true),
    );
  }

  Future<void> _runMotion({
    required Duration duration,
    required Curve curve,
    required Offset Function(double) path,
    required VoidCallback onDone,
  }) async {
    _motionPath = (t) => path(curve.transform(t));
    _motion.duration = duration;
    await _motion.forward(from: 0).orCancel.catchError((_) {});
    if (!mounted) return;
    _motionPath = null;
    onDone();
  }

  void _onMotionTick() {
    final path = _motionPath;
    if (path == null) return;
    setState(() => _shown = path(_motion.value));
  }

  void _finishTurn(PageTurn active, {required bool committed}) {
    final nextPage = committed
        ? (active.forward ? _page + 1 : _page - 1)
        : _page;
    setState(() {
      _turn = null;
      _page = nextPage;
    });
    if (!committed) return;
    widget.controller?._settle(_page);
    widget.onPageChanged?.call(_page);
  }

  void _onTapUp(TapUpDetails details) {
    if (_busy || _turn != null) return;
    final x = details.localPosition.dx;
    final edge = widget.enableTapToFlip ? widget.edgeTapFraction : 0.0;
    if (x > _size.width * (1 - edge)) {
      _autoTurn(forward: true);
    } else if (x < _size.width * edge) {
      _autoTurn(forward: false);
    } else {
      widget.onCenterTap?.call();
    }
  }

  Widget _pageAt(int index) => RepaintBoundary(
    key: ValueKey(index),
    child: widget.itemBuilder(context, index),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final drag = widget.enableDrag;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onTapUp: _onTapUp,
          onHorizontalDragStart: drag ? _onDragStart : null,
          onHorizontalDragUpdate: drag ? _onDragUpdate : null,
          onHorizontalDragEnd: drag ? _onDragEnd : null,
          child: ClipRect(child: _layers()),
        );
      },
    );
  }

  Widget _layers() {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    final active = _turn;
    if (active == null) return _pageAt(_page);
    final fold = PageFold.resolve(
      size: _size,
      corner: active.corner,
      finger: _shown,
    );
    if (fold == null) return _pageAt(active.index);
    return Stack(
      fit: StackFit.expand,
      children: [
        _pageAt(active.index + 1),
        ClipPath(
          clipper: PathClipper(fold.frontPath),
          child: _pageAt(active.index),
        ),
        IgnorePointer(child: CustomPaint(painter: PageFoldUnderPainter(fold))),
        ClipPath(
          clipper: PathClipper(fold.flapPath),
          child: Transform(
            transform: fold.reflection,
            child: ColoredBox(
              color: widget.paperColor,
              child: Opacity(
                opacity: widget.backsideOpacity,
                child: _pageAt(active.index),
              ),
            ),
          ),
        ),
        IgnorePointer(child: CustomPaint(painter: PageFoldFlapPainter(fold))),
      ],
    );
  }
}
