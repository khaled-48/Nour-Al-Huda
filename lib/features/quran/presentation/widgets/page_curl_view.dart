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
/// (114 سورة، بعضها بمئات الآيات). هذا العارض يبني فقط الصفحة الحالية،
/// ويبني الصفحة المجاورة فقط لحظة بدء السحب فعلياً نحوها (تحميل كسول
/// حقيقي، تماماً كسلوك PageView السابق).
///
/// آلية العمل: عند بدء السحب تُلتقط الصفحة الحالية والصفحة الوجهة كصورتين
/// ثابتتين (RepaintBoundary.toImage) مرة واحدة فقط، ثم تُرسم كل حركة
/// السحب بعد ذلك عبر CustomPainter (تحويلات بسيطة على الصورتين الجاهزتين)
/// بلا أي إعادة بناء لمحتوى الصفحة الثقيل، فتبقى كل إطارات السحب رخيصة
/// الحساب بغضّ النظر عن ثقل محتوى الصفحة نفسها (عدد الآيات، حجم النص...).
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
  int? _adjacentIndex;
  bool _dragging = false;
  bool _capturing = false;

  final GlobalKey _currentKey = GlobalKey();
  final GlobalKey _adjacentKey = GlobalKey();
  ui.Image? _currentImage;
  ui.Image? _adjacentImage;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _settleController.dispose();
    _currentImage?.dispose();
    _adjacentImage?.dispose();
    super.dispose();
  }

  bool get _isRtl => Directionality.of(context) == TextDirection.rtl;

  Future<ui.Image?> _capture(GlobalKey key) async {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    final pixelRatio = math.min(MediaQuery.of(context).devicePixelRatio, 2.5);
    return renderObject.toImage(pixelRatio: pixelRatio);
  }

  Future<void> _beginDrag(bool forward) async {
    final targetIndex = _currentIndex + (forward ? 1 : -1);
    if (targetIndex < 0 || targetIndex >= widget.itemCount) return;
    if (_capturing) return;

    _dragging = true;
    _capturing = true;
    setState(() => _adjacentIndex = targetIndex);

    // إطاران حتى تُبنى الصفحة المجاورة وتُرسم فعلياً قبل التقاطها كصورة.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _adjacentIndex != targetIndex) return;

    final current = await _capture(_currentKey);
    final adjacent = await _capture(_adjacentKey);
    if (!mounted || _adjacentIndex != targetIndex) {
      current?.dispose();
      adjacent?.dispose();
      return;
    }
    setState(() {
      _currentImage = current;
      _adjacentImage = adjacent;
      _capturing = false;
    });
  }

  void _onDragUpdate(double deltaFraction) {
    if (!_dragging) return;
    setState(() => _dragT = (_dragT + deltaFraction).clamp(-1.0, 1.0));
  }

  Future<void> _onDragEnd(double velocityFraction) async {
    if (!_dragging) return;
    const threshold = 0.35;
    final projected = _dragT + velocityFraction * 0.15;
    final hasTarget = _adjacentIndex != null && _currentImage != null;
    final shouldCommit = hasTarget && projected.abs() >= threshold;

    if (shouldCommit) {
      await _animateDragTo(_dragT >= 0 ? 1.0 : -1.0);
      _commit(_adjacentIndex!);
    } else {
      await _animateDragTo(0);
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
    _adjacentImage?.dispose();
    setState(() {
      _currentIndex = newIndex;
      _adjacentIndex = null;
      _currentImage = null;
      _adjacentImage = null;
      _dragT = 0;
      _dragging = false;
    });
    widget.onIndexChanged?.call(newIndex);
  }

  void _cancel() {
    _currentImage?.dispose();
    _adjacentImage?.dispose();
    setState(() {
      _adjacentIndex = null;
      _currentImage = null;
      _adjacentImage = null;
      _dragT = 0;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showPainter = _currentImage != null && _adjacentImage != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = constraints.biggest;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final dx = details.primaryDelta ?? 0;
            final directionalDx = _isRtl ? -dx : dx;
            if (!_dragging && !_capturing) {
              unawaited(_beginDrag(directionalDx > 0));
            }
            final width = _viewportSize.width;
            if (width > 0) _onDragUpdate(directionalDx / width);
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.velocity.pixelsPerSecond.dx;
            final directionalVelocity = _isRtl ? -velocity : velocity;
            final width = _viewportSize.width;
            unawaited(_onDragEnd(width > 0 ? directionalVelocity / width : 0));
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_adjacentIndex != null)
                Opacity(
                  opacity: showPainter ? 0 : 1,
                  child: RepaintBoundary(
                    key: _adjacentKey,
                    child: widget.itemBuilder(context, _adjacentIndex!),
                  ),
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
                        adjacentImage: _adjacentImage!,
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
