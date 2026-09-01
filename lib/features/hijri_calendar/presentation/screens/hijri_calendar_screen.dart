import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../core/widgets/gold_icon_button.dart';
import '../widgets/hijri_calendar_grid.dart';

/// تقويم هجري كامل قابل للتصفح شهراً بشهر، مع تمييز يوم اليوم والمناسبات
/// الدينية الثابتة. التنقّل بين الأشهر يُحسَب يدوياً (بلا استخدام
/// `HijriCalendar.addMonth`، ففيها علّة لا تزيد السنة عند التقدّم للأمام من
/// ذي الحجة).
class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = HijriCalendar.now();
    _year = now.hYear;
    _month = now.hMonth;
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthName = (HijriCalendar()..hMonth = _month).getLongMonthName();

    return Scaffold(
      appBar: AppBar(
        title: Text('$monthName $_year هـ'),
        actions: [
          GoldIconButton(
            icon: Icons.chevron_right,
            tooltip: 'الشهر السابق',
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: _previousMonth,
          ),
          GoldIconButton(
            icon: Icons.chevron_left,
            tooltip: 'الشهر التالي',
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: _nextMonth,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: HijriCalendarGrid(year: _year, month: _month),
      ),
    );
  }
}
