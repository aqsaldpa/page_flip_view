import 'dart:async';
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
    this.enableZoom = true,
    this.maxScale = 4,
    this.doubleTapScale = 2.5,
    this.onZoomChanged,
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

  /// Whether pinch and double tap zoom into the current page. While zoomed,
  /// one finger pans the page and turning is paused until you zoom out.
  final bool enableZoom;

  /// Largest zoom factor.
  final double maxScale;

  /// Zoom factor a double tap jumps to. Double tap again to zoom out.
  final double doubleTapScale;

  /// Called with the zoom factor of the current page whenever a zoom
  /// gesture or animation settles (1 means not zoomed). Useful to load a
  /// sharper version of the page.
  final ValueChanged<double>? onZoomChanged;

  @override
  State<PageFlipView> createState() => _PageFlipViewState();
}

class _PageFlipViewState extends State<PageFlipView>
    with TickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);
  late final Ticker _follow = createTicker(_onFollowTick);
  late final AnimationController _zoomMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  late int _page = widget.controller?.page ?? widget.initialPage;
  PageTurn? _turn;
  Size _size = Size.zero;
  Offset _shown = Offset.zero;
  Offset _target = Offset.zero;
  Offset _dragStart = Offset.zero;
  Duration _lastTick = Duration.zero;
  Offset Function(double)? _motionPath;

  double _scale = 1;
  Offset _pan = Offset.zero;
  double _gestureStartScale = 1;
  Offset _gestureStartPan = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;
  bool _zooming = false;
  Timer? _pendingTap;
  Offset _lastTapAt = Offset.zero;
  VoidCallback? _zoomListener;

  bool get _zoomed => _scale > 1.01;

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
    _zoomMotion.dispose();
    _pendingTap?.cancel();
    super.dispose();
  }

  void _jumpTo(int page) {
    _follow.stop();
    _motion.stop();
    _resetZoom();
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

  void _onScaleStart(ScaleStartDetails details) {
    if (_busy) return;
    _zoomMotion.stop();
    _dragStart = details.localFocalPoint;
    _gestureStartFocal = details.localFocalPoint;
    _gestureStartScale = _scale;
    _gestureStartPan = _pan;
    _zooming = false;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_busy) return;
    final pinching = details.pointerCount >= 2 && widget.enableZoom;
    if (_turn == null && (pinching || _zoomed || _zooming)) {
      _updateZoom(details, pinching: pinching);
      return;
    }
    if (widget.enableDrag) _updateTurn(details.localFocalPoint);
  }

  void _updateZoom(ScaleUpdateDetails details, {required bool pinching}) {
    if (!_zooming) {
      _zooming = true;
      _gestureStartFocal = details.localFocalPoint;
      _gestureStartScale = _scale;
      _gestureStartPan = _pan;
    }
    final scale = pinching
        ? (_gestureStartScale * details.scale).clamp(1.0, widget.maxScale)
        : _scale;
    final anchor = (_gestureStartFocal - _gestureStartPan) / _gestureStartScale;
    final pan = pinching
        ? details.localFocalPoint - anchor * scale
        : _gestureStartPan + (details.localFocalPoint - _gestureStartFocal);
    setState(() {
      _scale = scale;
      _pan = _clampPan(pan, scale);
    });
  }

  Offset _clampPan(Offset pan, double scale) => Offset(
    pan.dx.clamp(_size.width * (1 - scale), 0.0),
    pan.dy.clamp(_size.height * (1 - scale), 0.0),
  );

  void _updateTurn(Offset position) {
    final delta = position - _dragStart;
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

  void _onScaleEnd(ScaleEndDetails details) {
    if (_zooming) {
      _zooming = false;
      if (_scale < 1.05) {
        _animateZoom(1, Offset.zero);
      } else {
        widget.onZoomChanged?.call(_scale);
      }
      return;
    }
    _endTurn(details.velocity.pixelsPerSecond.dx);
  }

  void _toggleZoomAt(Offset position) {
    if (!widget.enableZoom || _busy || _turn != null) return;
    if (_zoomed) {
      _animateZoom(1, Offset.zero);
      return;
    }
    final scale = widget.doubleTapScale.clamp(1.0, widget.maxScale);
    _animateZoom(scale, _clampPan(position * (1 - scale), scale));
  }

  void _animateZoom(double scale, Offset pan) {
    final fromScale = _scale;
    final fromPan = _pan;
    final listener = _zoomListener;
    if (listener != null) _zoomMotion.removeListener(listener);
    void tick() {
      final t = Curves.easeOutCubic.transform(_zoomMotion.value);
      setState(() {
        _scale = fromScale + (scale - fromScale) * t;
        _pan = Offset.lerp(fromPan, pan, t) ?? pan;
      });
    }

    _zoomListener = tick;
    _zoomMotion.addListener(tick);
    _zoomMotion.forward(from: 0).then((_) {
      if (mounted) widget.onZoomChanged?.call(_scale);
    }, onError: (_) {});
  }

  void _resetZoom() {
    if (!_zoomed && _pan == Offset.zero) return;
    _zoomMotion.stop();
    _scale = 1;
    _pan = Offset.zero;
    widget.onZoomChanged?.call(1);
  }

  void _onFollowTick(Duration elapsed) {
    final frames = _lastTick == Duration.zero
        ? 1.0
        : (elapsed - _lastTick).inMicroseconds / 16667;
    _lastTick = elapsed;
    final alpha = 1 - math.pow(1 - widget.followFactor, frames).toDouble();
    setState(() => _shown = Offset.lerp(_shown, _target, alpha) ?? _target);
  }

  void _endTurn(double velocity) {
    final active = _turn;
    if (active == null || _busy) return;
    _follow.stop();
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
    final position = details.localPosition;
    final edge = widget.enableTapToFlip && !_zoomed
        ? widget.edgeTapFraction
        : 0.0;
    if (position.dx > _size.width * (1 - edge)) {
      _autoTurn(forward: true);
      return;
    }
    if (position.dx < _size.width * edge) {
      _autoTurn(forward: false);
      return;
    }
    _onMiddleTap(position);
  }

  void _onMiddleTap(Offset position) {
    final pending = _pendingTap;
    if (widget.enableZoom &&
        pending != null &&
        pending.isActive &&
        (position - _lastTapAt).distance < 40) {
      pending.cancel();
      _pendingTap = null;
      _toggleZoomAt(position);
      return;
    }
    if (!widget.enableZoom) {
      widget.onCenterTap?.call();
      return;
    }
    _lastTapAt = position;
    _pendingTap?.cancel();
    _pendingTap = Timer(kDoubleTapTimeout, () {
      _pendingTap = null;
      if (mounted) widget.onCenterTap?.call();
    });
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
          onScaleStart: drag || widget.enableZoom ? _onScaleStart : null,
          onScaleUpdate: drag || widget.enableZoom ? _onScaleUpdate : null,
          onScaleEnd: drag || widget.enableZoom ? _onScaleEnd : null,
          child: ClipRect(child: _layers()),
        );
      },
    );
  }

  Widget _layers() {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    final active = _turn;
    if (active == null) {
      if (!_zoomed) return _pageAt(_page);
      return Transform(
        transform: Matrix4.translationValues(_pan.dx, _pan.dy, 0)
          ..multiply(Matrix4.diagonal3Values(_scale, _scale, 1)),
        child: _pageAt(_page),
      );
    }
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
