import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// عارض صفحات بتأثير طيّ ورقي واقعي (Page Curl) بزاوية طيّ قطرية تلتصق
/// بموضع لمس الإصبع (x, y) بدقة وتتحرّك معه بنسبة 1:1، تماماً كتقليب زاوية
/// صفحة كتاب حقيقية (على غرار iBooks/Kindle) بدل الانزلاق الأفقي المسطّح.
///
/// مبني يدوياً بدل استخدام حزمة جاهزة لأن كل حزم "page curl" المتاحة على
/// pub.dev تبني كل صفحات القائمة دفعة واحدة عند الفتح (قائمة widgets
/// كاملة مسبقة البناء)، وهذا غير مناسب لعدد كبير من الصفحات الثقيلة
/// (114 سورة، بعضها بمئات الآيات).
///
/// آلية العمل: الصفحتان المجاورتان (السابقة والتالية) تُبنيان وتُلتقطان
/// كصورتين ثابتتين (RepaintBoundary.toImage) بشكل استباقي فور استقرار
/// الصفحة الحالية، ثم تُزالان فوراً من شجرة الودجت (تبقى الصورتان
/// الملتقطتان فقط، لا الودجت الثقيل نفسه). وأثناء السحب الفعلي، موضع
/// اللمس (ValueNotifier) هو الشيء الوحيد المتغيّر كل إطار: يُعاد رسم
/// [CustomPaint] فقط عبر [ValueListenableBuilder] بدل إعادة بناء شجرة
/// الصفحة الثقيلة (itemBuilder) نفسها في كل حركة إصبع، وحاوية التمويه
/// (ImageShader) تُبنى مرة واحدة فقط عند بدء السحب لا في كل إطار — فتبقى
/// كل إطارات السحب رخيصة الحساب بغضّ النظر عن ثقل محتوى الصفحة نفسها.
class PageCurlView extends StatefulWidget {
  const PageCurlView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.initialIndex,
    this.onIndexChanged,
    this.semanticLabel,
    this.prefetch,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  /// يُستدعى ويُنتظر لكل صفحة مجاورة قبل بنائها والتقاط لقطتها، حتى تكتمل
  /// أي تحميلات غير متزامنة (بيانات/خطوط) خاصة بمحتوى تلك الصفحة أولاً -
  /// وإلا فقد تُلتقط اللقطة قبل اكتمالها فتظهر أخفّ/ناقصة طوال حركة السحب
  /// كلها (لأن اللقطة تبقى ثابتة بعد التقاطها ولا تُحدَّث أثناء السحب).
  final Future<void> Function(int index)? prefetch;

  /// وصف عام للمحتوى يُقرأ لمستخدمي قارئات الشاشة (TalkBack/VoiceOver)،
  /// مثل "قارئ السور". القيمة المعروضة (رقم الصفحة الحالية من الإجمالي)
  /// تُضاف تلقائياً، ولا داعي لتضمينها هنا.
  final String? semanticLabel;

  @override
  State<PageCurlView> createState() => _PageCurlViewState();
}

class _PageCurlViewState extends State<PageCurlView>
    with SingleTickerProviderStateMixin {
  late int _currentIndex = widget.initialIndex;
  late final AnimationController _settleController;

  /// نقطة بداية السحب (إحداثيات محلية)، والفرق التراكمي عنها — وهو ما
  /// تتحرّك به زاوية الورقة المُمسوكة بمقدار مطابق تماماً (1:1) بغضّ النظر
  /// عن أين وضع المستخدم إصبعه فعلياً على الصفحة عند البداية. مُخزَّن في
  /// ValueNotifier (لا حقل عادي + setState) حتى لا تُعاد شجرة الصفحة
  /// الثقيلة (itemBuilder) بناءً مع كل حركة إصبع أثناء السحب.
  Offset? _dragStartLocal;
  final ValueNotifier<Offset> _cornerDelta = ValueNotifier(Offset.zero);

  /// أي نصف رأسي (علوي/سفلي) لمسه المستخدم عند بداية السحب — يحدّد الزاوية
  /// (علوية أو سفلية) التي "تُمسك" بها الورقة طوال هذه اللفتة.
  bool _cornerIsTop = false;

  /// null = الاتجاه لم يتحدّد بعد (لم يتجاوز السحب منطقة ميتة صغيرة منذ
  /// بدايته)؛ true = تقدّم للأمام (الصفحة التالية)، false = رجوع للخلف.
  bool? _forward;

  bool _dragging = false;

  final GlobalKey _currentKey = GlobalKey();
  final GlobalKey _prevKey = GlobalKey();
  final GlobalKey _nextKey = GlobalKey();

  ui.Image? _currentImage;
  ui.Image? _prevImage;
  ui.Image? _nextImage;

  /// حاوية التمويه (ImageShader) الخاصة بالصفحة الحالية، مبنيّة مرّة واحدة
  /// فور التقاطها لا في كل إطار سحب — إنشاء ImageShader جديد كل إطار كان
  /// يثقّل كل حركة إصبع بلا داعٍ رغم أن الصورة المصدر لا تتغيّر أثناء نفس
  /// السحبة.
  Paint? _warpPaint;

  /// أثناء إعادة تخزين صور الجيران مؤقتاً تُبنى صفحاتهما (خفية بالشفافية)
  /// لحظة الالتقاط فقط، ثم تُزال. هذا يتحكّم بذلك البناء المؤقت.
  bool _needsPrevBuild = false;
  bool _needsNextBuild = false;
  bool _refreshingNeighbors = false;
  bool _capturingCurrent = false;

  Size _viewportSize = Size.zero;

  /// حجم الإطار وقت التقاط صور الجيران الحالية. عند تغيّر الحجم (تدوير
  /// الجهاز، أو تبديل بين الوضع الرأسي/الأفقي على التابلت) تصبح هذه
  /// الصور بأبعاد قديمة وسترسم ممطوطة، لذا نعيد التقاطها بالحجم الجديد.
  Size? _neighborCacheSize;

  /// أقل إزاحة أفقية (بالبكسل المنطقي) قبل تحديد اتجاه السحب، لتفادي
  /// اهتزاز بسيط في بداية اللمس يُقرأ خطأً كاتجاه.
  static const _deadZone = 4.0;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _refreshNeighborCache(),
    );
  }

  @override
  void dispose() {
    _settleController.dispose();
    _cornerDelta.dispose();
    _currentImage?.dispose();
    _prevImage?.dispose();
    _nextImage?.dispose();
    super.dispose();
  }

  double get _capturePixelRatio =>
      math.min(MediaQuery.of(context).devicePixelRatio, 2.0);

  /// يُلتقط ضمن try/catch عمداً: toImage() تفترض أن الجدار مرسوم فعلاً في
  /// الإطار الحالي (`!debugNeedsPaint`)، لكن سباقاً نادراً - خروج المستخدم
  /// من الشاشة (زر الرجوع) بالضبط أثناء انتظار endOfFrame أعلاه، أو تغيّر
  /// حجم الإطار في نفس اللحظة - قد يترك الجدار عالقاً بحاجة رسم رغم اجتياز
  /// ذلك الانتظار، فترمي الدالة استثناءً بدل إعادة صورة. فشل التقاط جار
  /// واحد ليس خطأً فادحاً هنا: الجهتان المستدعيتان أصلاً تتعاملان مع نتيجة
  /// null بلا مشكلة (يبقى بلا تأثير طيّ لتلك الجهة حتى محاولة لاحقة ناجحة).
  Future<ui.Image?> _capture(GlobalKey key) async {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    try {
      return await renderObject.toImage(pixelRatio: _capturePixelRatio);
    } on AssertionError {
      return null;
    }
  }

  /// يبني الصفحتين المجاورتين مؤقتاً (بشفافية صفر) ليلتقطهما، ثم يزيلهما
  /// فوراً من الشجرة ولا يُبقي إلا الصورتين الملتقطتين.
  Future<void> _refreshNeighborCache() async {
    if (_refreshingNeighbors) return;
    _refreshingNeighbors = true;

    final wantsPrev = _currentIndex - 1 >= 0;
    final wantsNext = _currentIndex + 1 < widget.itemCount;
    final capturedForIndex = _currentIndex;

    if (widget.prefetch != null) {
      await Future.wait([
        if (wantsPrev) widget.prefetch!(_currentIndex - 1),
        if (wantsNext) widget.prefetch!(_currentIndex + 1),
      ]);
      if (!mounted || capturedForIndex != _currentIndex) {
        _refreshingNeighbors = false;
        return;
      }
    }

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
      _neighborCacheSize = _viewportSize;
    });
    _refreshingNeighbors = false;
  }

  Future<void> _beginDrag() async {
    if (_dragging || _capturingCurrent) return;
    _dragging = true;
    _capturingCurrent = true;
    await widget.prefetch?.call(_currentIndex);
    if (!mounted) return;
    final captured = await _capture(_currentKey);
    if (!mounted) return;
    _currentImage?.dispose();
    setState(() {
      _currentImage = captured;
      _warpPaint = captured == null
          ? null
          : (Paint()
              ..shader = ImageShader(
                captured,
                TileMode.clamp,
                TileMode.clamp,
                Matrix4.identity().storage,
              ));
    });
    _capturingCurrent = false;
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartLocal = details.localPosition;
    _cornerIsTop = details.localPosition.dy < _viewportSize.height / 2;
    _forward = null;
    _cornerDelta.value = Offset.zero;
    if (!_dragging) unawaited(_beginDrag());
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final start = _dragStartLocal;
    if (start == null || !_dragging) return;
    final delta = details.localPosition - start;

    var forward = _forward;
    if (forward == null) {
      if (delta.dx.abs() < _deadZone) return;
      // زاوية الطيّ تُمسَك من الحافة اليسرى وتُسحب نحو اليمين للتقدّم
      // (فيبدأ الطيّ عند اليسار وينمو نحو اليمين)، ومن اليمنى نحو اليسار
      // للرجوع — سحب الزاوية بعيداً عن الصفحة (بدل داخلها) يجعل الطيّ
      // يبتلع الصفحة كلها فوراً بدل نموّه تدريجياً، لذا يتحدّد الاتجاه من
      // جهة السحب الفعلية لا من قاعدة ثابتة سلفاً.
      final wantsForward = delta.dx > 0;
      // لا نحدّد اتجاهاً لا توجد له صفحة (أول/آخر عنصر في القائمة).
      if (wantsForward && _currentIndex >= widget.itemCount - 1) return;
      if (!wantsForward && _currentIndex <= 0) return;
      forward = wantsForward;
      _forward = forward;
    }

    _cornerDelta.value = delta;
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (!_dragging) return;
    final forward = _forward;
    if (forward == null) {
      _cancel();
      return;
    }

    final width = _viewportSize.width;
    final delta = _cornerDelta.value;
    final progress = width > 0
        ? ((forward ? delta.dx : -delta.dx) / width)
        : 0.0;
    final velocityDx = details.velocity.pixelsPerSecond.dx;
    final velocityBoost = width > 0
        ? ((forward ? velocityDx : -velocityDx) / width) * 0.15
        : 0.0;

    const threshold = 0.35;
    final hasTarget = forward ? _nextImage != null : _prevImage != null;
    final shouldCommit = hasTarget && (progress + velocityBoost) >= threshold;

    await _animateSettle(commit: shouldCommit, forward: forward);

    if (shouldCommit) {
      _commit(forward ? _currentIndex + 1 : _currentIndex - 1);
    } else {
      _cancel();
    }
  }

  /// يحرّك زاوية الورقة من موضعها الحالي إما إلى خارج الشاشة تماماً
  /// (لإتمام التقليب) أو إلى موضعها الأصلي (لإلغائه والعودة لصفحة مسطّحة).
  Future<void> _animateSettle({
    required bool commit,
    required bool forward,
  }) async {
    final width = _viewportSize.width;
    final target = commit
        ? Offset(forward ? (width + 60) : -(width + 60), 0)
        : Offset.zero;

    final tween = Tween<Offset>(begin: _cornerDelta.value, end: target);
    _settleController.value = 0;
    void tick() => _cornerDelta.value = tween.evaluate(_settleController);
    _settleController.addListener(tick);
    await _settleController.animateTo(1.0, curve: Curves.easeOut);
    _settleController.removeListener(tick);
  }

  void _commit(int newIndex) {
    _currentImage?.dispose();
    _cornerDelta.value = Offset.zero;
    setState(() {
      _currentIndex = newIndex;
      _currentImage = null;
      _warpPaint = null;
      _dragStartLocal = null;
      _forward = null;
      _dragging = false;
    });
    widget.onIndexChanged?.call(newIndex);
    _refreshNeighborCache();
  }

  void _cancel() {
    _currentImage?.dispose();
    _cornerDelta.value = Offset.zero;
    setState(() {
      _currentImage = null;
      _warpPaint = null;
      _dragStartLocal = null;
      _forward = null;
      _dragging = false;
    });
  }

  /// انتقال فوري بلا تحريك السحب، لمستخدمي قارئات الشاشة (TalkBack/
  /// VoiceOver) الذين يستخدمون حركة "زيادة/إنقاص القيمة" بدل السحب الفعلي.
  String _pageLabel(int index) => '${index + 1} / ${widget.itemCount}';

  void _accessibilityJump(int newIndex) {
    if (newIndex < 0 ||
        newIndex >= widget.itemCount ||
        newIndex == _currentIndex) {
      return;
    }
    _commit(newIndex);
  }

  /// يدعم أزرار الأسهم يمين/يسار في ريموت أجهزة التلفاز (D-pad) للتنقّل
  /// الفوري بين الصفحات، بنفس منطق قفزة إمكانية الوصول أعلاه (بلا تحريك
  /// طيّ) - السحب باللمس يبقى الوسيلة الأساسية على الهاتف، وهذا إضافي لا
  /// يتعارض معه (تُتجاهل المفاتيح الأخرى).
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _accessibilityJump(_currentIndex + 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _accessibilityJump(_currentIndex - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = constraints.biggest;
        if (!_dragging &&
            _neighborCacheSize != null &&
            _neighborCacheSize != _viewportSize) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _refreshNeighborCache(),
          );
        }
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.semanticLabel,
          value: _pageLabel(_currentIndex),
          // increasedValue/decreasedValue مطلوبتان معاً مع value متى ما
          // كان onIncrease/onDecrease مفعّلتين، وإلا يفشل تأكيد الإطار
          // الداخلي (SemanticsNode.updateWith). عند الحدود (أول/آخر صفحة)
          // تبقيان مطابقتين لـ value، لأن التنقّل لا يتجاوز الحدود أصلاً.
          increasedValue: _pageLabel(
            (_currentIndex + 1).clamp(0, widget.itemCount - 1),
          ),
          decreasedValue: _pageLabel(
            (_currentIndex - 1).clamp(0, widget.itemCount - 1),
          ),
          onIncrease: () => _accessibilityJump(_currentIndex + 1),
          onDecrease: () => _accessibilityJump(_currentIndex - 1),
          child: Focus(
            autofocus: true,
            onKeyEvent: _onKey,
            child: GestureDetector(
              // شفاف الاختبار (opaque) عمداً: زاوية الطيّ يجب أن تتبع اللمس
              // في أي مكان من الصفحة (حتى الزوايا الفارغة بصرياً من محتوى)،
              // لا فقط فوق نص أو عنصر مرسوم فعلياً يحجز الحدث بنفسه.
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: (details) => unawaited(_onPanEnd(details)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // بلا Opacity(opacity: 0) هنا عمداً: فلاتر يتجاهل رسم أي شجرة
                  // شفافيتها صفر تماماً (تحسين أداء داخلي)، فتفشل toImage()
                  // لعدم وجود طبقة مرسومة أصلاً. الصفحة الحالية المعتمة أدناه
                  // (متأخرة في ترتيب Stack، فتُرسم فوقها) تكفي لإخفائهما بصرياً.
                  // كل شريحة (سابقة/حالية/تالية) ثابتة المكان في الشجرة (نفس
                  // الـ GlobalKey دوماً)، بينما المحتوى المعروض فيها يتغيّر مع
                  // تغيّر الفهرس. KeyedSubtree بمفتاح يحمل رقم الفهرس يجبر
                  // فلاتر على إنشاء عنصر/حالة جديدة عند تغيّر الفهرس بدل إعادة
                  // استخدام حالة الصفحة القديمة (State) بمحتوى مبني لفهرس آخر
                  // — وهو تحديداً ما كان يسبب قراءة بيانات صفحة سابقة (مثلاً
                  // قائمة بحجم مختلف) بفهرس يتجاوز حدودها.
                  if (_needsPrevBuild)
                    RepaintBoundary(
                      key: _prevKey,
                      child: KeyedSubtree(
                        key: ValueKey(_currentIndex - 1),
                        child: widget.itemBuilder(context, _currentIndex - 1),
                      ),
                    ),
                  if (_needsNextBuild)
                    RepaintBoundary(
                      key: _nextKey,
                      child: KeyedSubtree(
                        key: ValueKey(_currentIndex + 1),
                        child: widget.itemBuilder(context, _currentIndex + 1),
                      ),
                    ),
                  // ValueListenableBuilder يعزل إعادة الرسم أثناء السحب: كل
                  // حركة إصبع تُعيد بناء Opacity+CustomPaint فقط (عبر builder)
                  // بينما تُمرَّر شجرة الصفحة الثقيلة (itemBuilder) كوسيط
                  // child ثابت لا يُعاد بناؤه إطلاقاً خلال نفس السحبة.
                  ValueListenableBuilder<Offset>(
                    valueListenable: _cornerDelta,
                    builder: (context, cornerDelta, child) {
                      final forward = _forward;
                      final adjacentImage = forward == null
                          ? null
                          : (forward ? _nextImage : _prevImage);
                      final showPainter =
                          _currentImage != null &&
                          _warpPaint != null &&
                          adjacentImage != null &&
                          cornerDelta != Offset.zero;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(opacity: showPainter ? 0 : 1, child: child),
                          if (showPainter)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _PageCurlPainter(
                                    currentImage: _currentImage!,
                                    adjacentImage: adjacentImage,
                                    warpPaint: _warpPaint!,
                                    forward: forward!,
                                    cornerIsTop: _cornerIsTop,
                                    cornerDelta: cornerDelta,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    child: RepaintBoundary(
                      key: _currentKey,
                      child: KeyedSubtree(
                        key: ValueKey(_currentIndex),
                        child: widget.itemBuilder(context, _currentIndex),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void unawaited(Future<void> future) {}

/// يرسم الصفحة الحالية ([currentImage]) وهي تُطوى من إحدى زواياها (تحدّدها
/// [forward] للجهة الأفقية و[cornerIsTop] للجهة الرأسية) نحو موضع الإصبع
/// ([cornerDelta] عن تلك الزاوية)، كاشفةً [adjacentImage] (التالية أو
/// السابقة) تحتها. الهندسة كلها متجهات ثنائية الأبعاد بسيطة (نقطتان
/// وخطّ طيّ واحد)، و[warpPaint] (حاوية التمويه) مبنيّة مسبقاً خارج
/// الرسّام، فتبقى تكلفة كل إطار رخيصة مهما بلغت دقّة تتبّع الإصبع.
class _PageCurlPainter extends CustomPainter {
  _PageCurlPainter({
    required this.currentImage,
    required this.adjacentImage,
    required this.warpPaint,
    required this.forward,
    required this.cornerIsTop,
    required this.cornerDelta,
  });

  final ui.Image currentImage;
  final ui.Image adjacentImage;
  final Paint warpPaint;
  final bool forward;
  final bool cornerIsTop;
  final Offset cornerDelta;

  @override
  void paint(Canvas canvas, Size size) {
    _drawFit(canvas, adjacentImage, size);

    // الطيّ يبدأ من الحافة اليسرى وينمو نحو اليمين عند التقدّم للأمام، ومن
    // اليمنى نحو اليسار عند الرجوع للخلف (يطابق ذلك جهة السحب المطلوبة في
    // _onPanUpdate لتفادي طيّ الصفحة كلها فوراً).
    final restCorner = Offset(
      forward ? 0 : size.width,
      cornerIsTop ? 0 : size.height,
    );

    // بُعد السحب عن الزاوية الأصلية محدود بأقصى قطر للصفحة، لمنع هندسة
    // الطيّ من التطرّف إن سحب المستخدم إصبعه بعيداً جداً خارج حدود الشاشة.
    var f = restCorner + cornerDelta;
    final toF = f - restCorner;
    final dist = toF.distance;
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    if (dist > maxRadius && maxRadius > 0) {
      f = restCorner + toF * (maxRadius / dist);
    }

    final dir = f - restCorner;
    if (dir.distance < 0.5) {
      // لا سحب فعلياً بعد؛ الصفحة الحالية مسطّحة تماماً فوق الخلفية.
      _drawFit(canvas, currentImage, size);
      return;
    }
    final n = dir / dir.distance;
    final m = Offset.lerp(restCorner, f, 0.5)!;

    final rect = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];

    // مضلع جهة الزاوية الأصلية (الذي يُطوى) ومضلع الجهة المقابلة الثابتة،
    // بقصّ مستطيل الصفحة بخطّ الطيّ (المنصّف العمودي بين الزاوية وموضع
    // الإصبع) عبر خوارزمية Sutherland-Hodgman لنصف مستوٍ واحد.
    final flapPolygon = _clipHalfPlane(rect, m, n);
    final flatPolygon = _clipHalfPlane(rect, m, -n);

    if (flatPolygon.length >= 3) {
      canvas.save();
      canvas.clipPath(Path()..addPolygon(flatPolygon, true));
      _drawFit(canvas, currentImage, size);
      canvas.restore();
    }

    if (flapPolygon.length < 3) return;

    Offset reflect(Offset p) {
      final d = (p - m).dx * n.dx + (p - m).dy * n.dy;
      return p - n * (2 * d);
    }

    final reflectedPolygon = flapPolygon.map(reflect).toList(growable: false);
    final reflectedPath = Path()..addPolygon(reflectedPolygon, true);

    // ظل ناعم تلقيه الطيّة المرتفعة على ما تحتها (الصفحة المسطّحة أو
    // الخلفية)، عبر ظلّ Skia المدمج بدل حساب تدرّج يدوي.
    canvas.drawShadow(reflectedPath, Colors.black, 8, false);

    final scaleX = size.width / currentImage.width;
    final imageSpacePolygon = flapPolygon
        .map((p) => Offset(p.dx / scaleX, p.dy / scaleX))
        .toList(growable: false);

    // رسم محتوى الصفحة مموّهاً (Warped) داخل مضلع الطيّة المنعكس: المواضع
    // على الشاشة هي الرؤوس المنعكسة (تلتصق الزاوية فيها بموضع الإصبع
    // فعلياً)، بينما إحداثيات النسيج (texture) هي الرؤوس الأصلية نفسها
    // مسقَطة على بكسلات الصورة الملتقطة — فيبدو المحتوى وكأنه انطوى فعلاً.
    // warpPaint (حاوية التمويه) جاهزة مسبقاً؛ لا إنشاء جديد هنا كل إطار.
    _drawWarped(canvas, imageSpacePolygon, reflectedPolygon);

    // تظليل على الطيّة نفسها لمحاكاة انحناء الورقة: أفتح قرب خطّ الطيّ حيث
    // الضوء، وأغمق تدريجياً قرب الزاوية المرفوعة (موضع الإصبع).
    final shadeGradient = ui.Gradient.linear(
      m,
      f,
      [
        Colors.white.withValues(alpha: 0.30),
        Colors.black.withValues(alpha: 0.10),
        Colors.black.withValues(alpha: 0.45),
      ],
      const [0.0, 0.5, 1.0],
    );
    canvas.drawPath(reflectedPath, Paint()..shader = shadeGradient);
  }

  void _drawFit(Canvas canvas, ui.Image image, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  void _drawWarped(
    Canvas canvas,
    List<Offset> imageSpacePoints,
    List<Offset> screenPoints,
  ) {
    if (screenPoints.length < 3) return;

    final indices = <int>[
      for (var i = 1; i < screenPoints.length - 1; i++) ...[0, i, i + 1],
    ];

    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      screenPoints,
      textureCoordinates: imageSpacePoints,
      indices: indices,
    );

    canvas.drawVertices(vertices, BlendMode.srcOver, warpPaint);
  }

  /// يقصّ [polygon] بنصف المستوى `{p : dot(p - planePoint, normal) <= 0}`
  /// عبر Sutherland-Hodgman لحافة (خطّ) واحدة فقط.
  static List<Offset> _clipHalfPlane(
    List<Offset> polygon,
    Offset planePoint,
    Offset normal,
  ) {
    final result = <Offset>[];
    for (var i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final prev = polygon[(i - 1 + polygon.length) % polygon.length];
      final currentSide = _dot(current - planePoint, normal);
      final prevSide = _dot(prev - planePoint, normal);
      final currentInside = currentSide <= 0;
      final prevInside = prevSide <= 0;
      if (currentInside != prevInside) {
        final denom = prevSide - currentSide;
        final t = denom == 0 ? 0.0 : prevSide / denom;
        result.add(Offset.lerp(prev, current, t)!);
      }
      if (currentInside) result.add(current);
    }
    return result;
  }

  static double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  @override
  bool shouldRepaint(covariant _PageCurlPainter oldDelegate) {
    return oldDelegate.cornerDelta != cornerDelta ||
        oldDelegate.currentImage != currentImage ||
        oldDelegate.adjacentImage != adjacentImage ||
        oldDelegate.forward != forward ||
        oldDelegate.cornerIsTop != cornerIsTop;
  }
}
