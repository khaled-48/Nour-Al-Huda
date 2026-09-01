import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

/// شريط أدوات سفلي أنيق لصفحة قراءة القرآن: حفظ، مشاركة، تفسير، بحث،
/// ضبط الخط، ووضع القراءة - كل أداة أيقونة ذهبية فوق تسمية صغيرة، على
/// خلفية داكنة بحدّ علوي ذهبي رفيع.
class QuranReaderToolbar extends StatelessWidget {
  const QuranReaderToolbar({
    super.key,
    required this.isBookmarked,
    required this.onSave,
    required this.onShare,
    required this.onTafsir,
    required this.onSearch,
    required this.onFont,
    required this.isImmersive,
    required this.onToggleImmersive,
  });

  final bool isBookmarked;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onTafsir;
  final VoidCallback onSearch;
  final VoidCallback onFont;
  final bool isImmersive;
  final VoidCallback onToggleImmersive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10241E), Color(0xFF18332B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(top: BorderSide(color: AppColors.gold, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ToolbarAction(
                icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                label: 'حفظ',
                highlighted: isBookmarked,
                onTap: onSave,
              ),
              _ToolbarAction(icon: Icons.share_outlined, label: 'مشاركة', onTap: onShare),
              _ToolbarAction(icon: Icons.menu_book_outlined, label: 'تفسير', onTap: onTafsir),
              _ToolbarAction(icon: Icons.search, label: 'بحث', onTap: onSearch),
              _ToolbarAction(icon: Icons.text_fields, label: 'خط', onTap: onFont),
              _ToolbarAction(
                icon: isImmersive ? Icons.fullscreen_exit : Icons.fullscreen,
                label: 'وضع القراءة',
                highlighted: isImmersive,
                onTap: onToggleImmersive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.goldLight : AppColors.gold.withValues(alpha: 0.85);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20.sp, color: color),
              SizedBox(height: 3.h),
              Text(label, style: TextStyle(fontSize: 10.sp, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
