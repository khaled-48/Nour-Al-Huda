import 'package:flutter/material.dart';

/// لوحة ألوان مختارة بعناية (ذهبي/أخضر/أزرق/أحمر/محايدات...) بالإضافة إلى
/// مزيج RGB حرّ الحركة، حتى يملك المستخدم تحكماً كاملاً بلا الحاجة لحزمة
/// خارجية أو اتصال إنترنت.
const List<Color> kColorPalette = [
  Color(0xFFC9A227), // ذهبي (لون التطبيق الأساسي)
  Color(0xFFE0C170), // ذهبي فاتح
  Color(0xFF0F6E5C), // أخضر إسلامي
  Color(0xFF0A4A3D), // أخضر داكن
  Color(0xFF3E8E86), // فيروزي
  Color(0xFF1565C0), // أزرق
  Color(0xFF6A1B9A), // بنفسجي
  Color(0xFFB3261E), // أحمر
  Color(0xFFEF6C00), // برتقالي
  Color(0xFFFFFFFF), // أبيض
  Color(0xFFEDEDED), // رمادي فاتح جداً
  Color(0xFF9E9E9E), // رمادي
  Color(0xFF3A362E), // بنّي داكن
  Color(0xFF1B1B1B), // أسود تقريباً
  Color(0xFF000000), // أسود
];

/// يفتح لوحة اختيار لون: شبكة ألوان جاهزة + منزلقات RGB لمزيج حرّ، ويُعيد
/// اللون المُختار أو null إن أُلغي.
Future<Color?> showSimpleColorPicker({
  required BuildContext context,
  required String title,
  required Color initialColor,
}) {
  return showDialog<Color>(
    context: context,
    builder: (context) =>
        _ColorPickerDialog(title: title, initialColor: initialColor),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.title, required this.initialColor});

  final String title;
  final Color initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _color = widget.initialColor;

  void _setChannel({int? r, int? g, int? b}) {
    setState(() {
      _color = Color.fromARGB(
        255,
        r ?? (_color.r * 255).round(),
        g ?? (_color.g * 255).round(),
        b ?? (_color.b * 255).round(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = (_color.r * 255).round();
    final g = (_color.g * 255).round();
    final b = (_color.b * 255).round();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black26),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kColorPalette.map((swatch) {
                  final selected = swatch.toARGB32() == _color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _color = swatch),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black26,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _ChannelSlider(
                label: 'R',
                value: r,
                color: Colors.red,
                onChanged: (v) => _setChannel(r: v),
              ),
              _ChannelSlider(
                label: 'G',
                value: g,
                color: Colors.green,
                onChanged: (v) => _setChannel(g: v),
              ),
              _ChannelSlider(
                label: 'B',
                value: b,
                color: Colors.blue,
                onChanged: (v) => _setChannel(b: v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('تطبيق'),
        ),
      ],
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(width: 32, child: Text('$value')),
      ],
    );
  }
}
