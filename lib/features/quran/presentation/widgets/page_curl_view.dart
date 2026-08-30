import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// عارض صفحات بتأثير طيّ ورقي واقعي (Page Curl) يتبع سحب الإصبع لحظياً،
/// يحاكي تقليب صفحة كتاب حقيقي بدل الانزلاق الأفقي المسطّح.
///
/// مبني يدوياً بدل استخدام حزمة جاهزة لأن كل حزم "page curl" المتاحة على
/// pub.dev تبني كل صفحات القائمة دفعة واحدة عند الفتح (قائمة widgets
/// كاملة مسبقة البناء)، وهذا غير مناسب لعدد كبير من الصفحات الثقيلة
/// (114 سورة، بعضها بمئات الآيات).
///
/// آلية العمل: الصفحتان المجاورتان (السابقة والتالية) تُبنيان وتُلتقطان
/// كصورتين ثابتتين (RepaintBoundary.toImage) بشكل استباقي فور استقرار
/// الصفحة الحالية — تماماً كما كان `allowImplicitScrolling` يحمّل الجارة
/// مسبقاً — ثم تُزالان فوراً من شجرة الودجت (تبقى الصورتان الملتقطتان
/// فقط، لا الودجت الثقيل نفسه). لذا حين يبدأ المستخدم السحب فعلياً، لا
/// يوجد أي انتظار لبناء الصفحة الجديدة، فقط التقاطة سريعة إضافية للصفحة
/// الحالية المرسومة أصلاً. كل حركة السحب بعد ذلك تُرسم عبر CustomPainter
/// (تحويلات على الصور الجاهزة فقط)، فتبقى كل إطارات السحب رخيصة الحساب
/// بغضّ النظر عن ثقل محتوى الصفحة نفسها (عدد الآيات، حجم النص...).
class PageCurlView extends StatefulWidget {
  const PageCurlView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.initialIndex,
    this.onIndexChanged,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  @override
  State<PageCurlView> createState() => _PageCurlViewState();
}

class _PageCurlViewState extends State<PageCurlView>
    with SingleTickerProviderStateMixin {
  late int _currentIndex = widget.initialIndex;
  late final AnimationController _settleController;

  /// تقدّم السحب: من -1 إلى 1. الإشارة تحدد الاتجاه (موجب = تقدّم للأمام
  /// نحو الصفحة التالية، سالب = رجوع للصفحة السابقة)، والقيمة المطلقة هي
  /// نسبة اكتمال الطيّ.
  double _dragT = 0;
  bool _dragging = false;

  final GlobalKey _currentKey = GlobalKey();
  final GlobalKey _prevKey = GlobalKey();
  final GlobalKey _nextKey = GlobalKey();

  ui.Image? _currentImage;
  ui.Image? _prevImage;
  ui.Image? _nextImage;

  /// أثناء إعادة تخزين صور الجيران مؤقتاً تُبنى صفحاتهما (خفية بالشفافية)
  /// لحظة الالتقاط فقط، ثم تُزال. هذا يتحكّم بذلك البناء المؤقت.
  bool _needsPrevBuild = false;
  bool _needsNextBuild = false;
  bool _refreshingNeighbors = false;
  bool _capturingCurrent = false;

  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshNeighborCache());
  }

  @override
  void dispose() {
    _settleController.dispose();
    _currentImage?.dispose();
    _prevImage?.dispose();
    _nextImage?.dispose();
    super.dispose();
  }

  bool get _isRtl => Directionality.of(context) == TextDirection.rtl;

  double get _capturePixelRatio =>
      math.min(MediaQuery.of(context).devicePixelRatio, 2.0);

  Future<ui.Image?> _capture(GlobalKey key) async {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    return renderObject.toImage(pixelRatio: _capturePixelRatio);
  }

  /// يبني الصفحتين المجاورتين مؤقتاً (بشفافية صفر) ليلتقطهما، ثم يزيلهما
  /// فوراً من الشجرة ولا يُبقي إلا الصورتين الملتقطتين.
  Future<void> _refreshNeighborCache() async {
    if (_refreshingNeighbors) return;
    _refreshingNeighbors = true;

    final wantsPrev = _currentIndex - 1 >= 0;
    final wantsNext = _currentIndex + 1 < widget.itemCount;
    final capturedForIndex = _currentIndex;

    setState(() {
      _needsPrevBuild = wantsPrev;
      _needsNextBuild = wantsNext;
    });

    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || capturedForIndex != _currentIndex) {
      _refreshingNeighbors = false;
      return;
    }

    final newPrev = wantsPrev ? await _capture(_prevKey) : null;
    final newNext = wantsNext ? await _capture(_nextKey) : null;
    if (!mounted || capturedForIndex != _currentIndex) {
      newPrev?.dispose();
      newNext?.dispose();
      _refreshingNeighbors = false;
      return;
    }

    _prevImage?.dispose();
    _nextImage?.dispose();
    setState(() {
      _prevImage = newPrev;
      _nextImage = newNext;
      _needsPrevBuild = false;
      _needsNextBuild = false;
    });
    _refreshingNeighbors = false;
  }

  Future<void> _beginDrag() async {
    if (_dragging || _capturingCurrent) return;
    _dragging = true;
    _capturingCurrent = true;
    final captured = await _capture(_currentKey);
    if (!mounted) return;
    _currentImage?.dispose();
    setState(() => _currentImage = captured);
    _capturingCurrent = false;
  }

  void _onDragUpdate(double deltaFraction) {
    if (!_dragging) return;
    final atStart = _currentIndex == 0;
    final atEnd = _currentIndex == widget.itemCount - 1;
    var next = _dragT + deltaFraction;
    // لا نسمح بالسحب أبعد من حدود القائمة (لا صفحة سابقة/تالية).
    if (next < 0 && atStart) next = 0;
    if (next > 0 && atEnd) next = 0;
    setState(() => _dragT = next.clamp(-1.0, 1.0));
  }

  Future<void> _onDragEnd(double velocityFraction) async {
    if (!_dragging) return;
    const threshold = 0.35;
    final projected = _dragT + velocityFraction * 0.15;
    final target = projected >= threshold
        ? 1.0
        : (projected <= -threshold ? -1.0 : 0.0);

    await _animateDragTo(target);
    if (target == 1.0 && _nextImage != null) {
      _commit(_currentIndex + 1);
    } else if (target == -1.0 && _prevImage != null) {
      _commit(_currentIndex - 1);
    } else {
      _cancel();
    }
  }

  Future<void> _animateDragTo(double target) async {
    final tween = Tween<double>(begin: _dragT, end: target);
    _settleController.value = 0;
    void tick() => setState(() => _dragT = tween.evaluate(_settleController));
    _settleController.addListener(tick);
    await _settleController.animateTo(1.0, curve: Curves.easeOut);
    _settleController.removeListener(tick);
  }

  void _commit(int newIndex) {
    _currentImage?.dispose();
    setState(() {
      _currentIndex = newIndex;
      _currentImage = null;
      _dragT = 0;
      _dragging = false;
    });
    widget.onIndexChanged?.call(newIndex);
    _refreshNeighborCache();
  }

  void _cancel() {
    _currentImage?.dispose();
    setState(() {
      _currentImage = null;
      _dragT = 0;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adjacentImage = _dragT >= 0 ? _nextImage : _prevImage;
    final showPainter = _currentImage != null && adjacentImage != null && _dragT != 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = constraints.biggest;
        return GestureDetector(
          onHorizontalDragStart: (_) {
            if (!_dragging) unawaited(_beginDrag());
          },
          onHorizontalDragUpdate: (details) {
            final dx = details.primaryDelta ?? 0;
            final directionalDx = _isRtl ? dx : -dx;
            final width = _viewportSize.width;
            if (width > 0) _onDragUpdate(directionalDx / width);
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.velocity.pixelsPerSecond.dx;
            final directionalVelocity = _isRtl ? velocity : -velocity;
            final width = _viewportSize.width;
            unawaited(_onDragEnd(width > 0 ? directionalVelocity / width : 0));
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // بلا Opacity(opacity: 0) هنا عمداً: فلاتر يتجاهل رسم أي شجرة
              // شفافيتها صفر تماماً (تحسين أداء داخلي)، فتفشل toImage()
              // لعدم وجود طبقة مرسومة أصلاً. الصفحة الحالية المعتمة أدناه
              // (متأخرة في ترتيب Stack، فتُرسم فوقها) تكفي لإخفائهما بصرياً.
              if (_needsPrevBuild)
                RepaintBoundary(
                  key: _prevKey,
                  child: widget.itemBuilder(context, _currentIndex - 1),
                ),
              if (_needsNextBuild)
                RepaintBoundary(
                  key: _nextKey,
                  child: widget.itemBuilder(context, _currentIndex + 1),
                ),
              Opacity(
                opacity: showPainter ? 0 : 1,
                child: RepaintBoundary(
                  key: _currentKey,
                  child: widget.itemBuilder(context, _currentIndex),
                ),
              ),
              if (showPainter)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PageCurlPainter(
                        currentImage: _currentImage!,
                        adjacentImage: adjacentImage,
                        dragT: _dragT,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

void unawaited(Future<void> future) {}

class _PageCurlPainter extends CustomPainter {
  _PageCurlPainter({
    required this.currentImage,
    required this.adjacentImage,
    required this.dragT,
  });

  final ui.Image currentImage;
  final ui.Image adjacentImage;
  final double dragT;

  @override
  void paint(Canvas canvas, Size size) {
    final forward = dragT >= 0;
    final progress = dragT.abs();

    final background = forward ? adjacentImage : currentImage;
    final rolling = forward ? currentImage : adjacentImage;

    _drawFit(canvas, background, size);

    final foldX = size.width * (forward ? (1 - progress) : progress);
    final curlWidth = math.min(size.width * 0.12, 46.0);

    final scaleX = size.width / rolling.width;
    final rollingHeightPx = rolling.height.toDouble();

    if (foldX > 0) {
      final srcRect = Rect.fromLTWH(0, 0, foldX / scaleX, rollingHeightPx);
      final dstRect = Rect.fromLTWH(0, 0, foldX, size.height);
      canvas.drawImageRect(rolling, srcRect, dstRect, Paint());
    }

    final rollingWidthPx = rolling.width.toDouble();
    final stripSrcX = (foldX / scaleX).clamp(0.0, math.max(0.0, rollingWidthPx - 1)).toDouble();
    final stripSrcWidth = math.max(0.0, math.min(curlWidth / scaleX, rollingWidthPx - stripSrcX));
    if (stripSrcWidth <= 0) return;

    final dstWidth = math.max(0.0, math.min(curlWidth * 0.7, size.width - foldX));
    if (dstWidth <= 0) return;

    final srcStripRect = Rect.fromLTWH(stripSrcX, 0, stripSrcWidth, rollingHeightPx);
    final dstStripRect = Rect.fromLTWH(foldX, 0, dstWidth, size.height);
    canvas.drawImageRect(rolling, srcStripRect, dstStripRect, Paint());

    final shadeGradient = ui.Gradient.linear(
      Offset(dstStripRect.left, 0),
      Offset(dstStripRect.right, 0),
      [
        Colors.white.withValues(alpha: 0.35),
        Colors.black.withValues(alpha: 0.05),
        Colors.black.withValues(alpha: 0.45),
      ],
      const [0.0, 0.45, 1.0],
    );
    canvas.drawRect(dstStripRect, Paint()..shader = shadeGradient);

    final shadowWidth = math.min(28.0, size.width - dstStripRect.right);
    if (shadowWidth > 0) {
      final shadowRect = Rect.fromLTWH(dstStripRect.right, 0, shadowWidth, size.height);
      final shadowGradient = ui.Gradient.linear(
        Offset(shadowRect.left, 0),
        Offset(shadowRect.right, 0),
        [Colors.black.withValues(alpha: 0.28), Colors.transparent],
      );
      canvas.drawRect(shadowRect, Paint()..shader = shadowGradient);
    }
  }

  void _drawFit(Canvas canvas, ui.Image image, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _PageCurlPainter oldDelegate) {
    return oldDelegate.dragT != dragT ||
        oldDelegate.currentImage != currentImage ||
        oldDelegate.adjacentImage != adjacentImage;
  }
}
