import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/settings/numeral_style_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/numeral_formatter.dart';
import '../../../../core/widgets/islamic_pattern_background.dart';
import '../../data/prayer_times_repository.dart';
import '../providers/location_provider.dart';
import '../widgets/compass_dial_painter.dart';

/// أقصى فرق زاوية (بالدرجات) بين اتجاه السهم الحالي والقبلة يُعتبر بعده
/// "محاذاة" مقبولة، فيتحول لون السهم من الذهبي إلى الأخضر الإسلامي.
const _alignmentToleranceDegrees = 4.0;

/// بوصلة اتجاه القبلة: تحسب زاوية القبلة فلكياً من موقع المستخدم الحالي
/// (بدون إنترنت)، ثم تدور سهماً ذهبياً باستمرار حسب قراءة حساس المجال
/// المغناطيسي بالجهاز حتى يشير دائماً ناحية الكعبة المشرّفة أينما اتجه
/// المستخدم بهاتفه.
class QiblaCompassScreen extends ConsumerWidget {
  const QiblaCompassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('اتجاه القبلة')),
      body: IslamicPatternBackground(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        patternColor: AppColors.gold,
        child: SafeArea(
          child: locationAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _MessageView(
              icon: Icons.location_off_outlined,
              message: 'تعذّر تحديد الموقع: $error',
              onRetry: () => ref.read(locationProvider.notifier).refresh(),
            ),
            data: (position) {
              const repository = PrayerTimesRepository();
              final qiblaBearing = repository.qiblaDirection(
                latitude: position.latitude,
                longitude: position.longitude,
              );
              final distanceKm = repository.distanceToMeccaKm(
                latitude: position.latitude,
                longitude: position.longitude,
              );
              return _CompassBody(qiblaBearing: qiblaBearing, distanceKm: distanceKm);
            },
          ),
        ),
      ),
    );
  }
}

class _CompassBody extends ConsumerWidget {
  const _CompassBody({required this.qiblaBearing, required this.distanceKm});

  final double qiblaBearing;
  final double distanceKm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numeralStyle = ref.watch(numeralStyleProvider);
    final compassStream = FlutterCompass.events;

    if (compassStream == null) {
      return const _MessageView(
        icon: Icons.explore_off_outlined,
        message: 'لا تتوفر بوصلة (حساس مجال مغناطيسي) على هذا الجهاز.',
      );
    }

    final distanceLabel = formatNumerals(
      '${intl.NumberFormat('#,##0', 'en').format(distanceKm)} كم',
      numeralStyle,
    );

    return StreamBuilder<CompassEvent>(
      stream: compassStream,
      builder: (context, snapshot) {
        final heading = snapshot.data?.heading;

        if (heading == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // heading = الاتجاه البوصلي الذي يشير إليه أعلى الشاشة حالياً (٠=شمال،
        // ٩٠=شرق، بالتوثيق الرسمي لـflutter_compass). لجعل السهم يشير دائماً
        // نحو qiblaBearing الثابتة، ندوّره بمقدار الفرق بينها وبين heading؛
        // القيمة الموجبة في AnimatedRotation.turns تدور مع عقارب الساعة، وهو
        // ما يطابق أن زيادة الاتجاه البوصلي (heading) نفسها مع عقارب الساعة.
        // تم التحقق من صحة هذه المعادلة ميدانياً على الجهاز الفعلي.
        final turns = (qiblaBearing - heading) / 360;

        final rawDiff = (qiblaBearing - heading) % 360;
        final signedDiff = rawDiff > 180 ? rawDiff - 360 : rawDiff;
        final angularError = signedDiff.abs();
        final isAligned = angularError <= _alignmentToleranceDegrees;

        final arrowColor = isAligned ? AppColors.primary : AppColors.gold;
        final size = 260.w;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size + 36.w,
                height: size + 36.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: size + (isAligned ? 36.w : 12.w),
                      height: size + (isAligned ? 36.w : 12.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            arrowColor.withValues(alpha: isAligned ? 0.28 : 0.12),
                            arrowColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(size, size),
                            painter: CompassDialPainter(color: AppColors.gold),
                          ),
                          Align(
                            alignment: const Alignment(0, -1),
                            child: Padding(
                              padding: EdgeInsets.only(top: 6.h),
                              child: Text('🕋', style: TextStyle(fontSize: 20.sp)),
                            ),
                          ),
                          AnimatedRotation(
                            turns: turns,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: Icon(Icons.navigation, size: 90.sp, color: arrowColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),
              isAligned
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16.sp, color: AppColors.primary),
                        SizedBox(width: 6.w),
                        Text(
                          'أنت متجه الآن نحو القبلة',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    )
                  : Text('اتجاه القبلة من الشمال', style: TextStyle(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              Text(
                formatNumerals('${qiblaBearing.round()}°', numeralStyle),
                style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold, color: AppColors.gold),
              ),
              SizedBox(height: 8.h),
              Text(
                'المسافة إلى مكة المكرمة: $distanceLabel',
                style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.outline),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  'أدر جسمك حتى يشير السهم للأعلى مباشرة. إن بدت البوصلة غير دقيقة، حرّك هاتفك برسم رقم ٨ في الهواء لمعايرتها.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5.sp, color: Theme.of(context).colorScheme.outline),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message, this.onRetry});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56.sp, color: Theme.of(context).colorScheme.error),
            SizedBox(height: 16.h),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp)),
            if (onRetry != null) ...[
              SizedBox(height: 20.h),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
