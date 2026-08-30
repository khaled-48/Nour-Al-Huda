import 'package:flutter/material.dart';

/// منتقي ألوان حر بلا أي قيود على القيمة النهائية (Hue/Saturation/Lightness)،
/// مبني بالكامل بأدوات فلاتر القياسية دون أي حزمة خارجية.
class HslColorPicker extends StatefulWidget {
  const HslColorPicker({super.key, required this.initialColor, required this.onChanged});

  final Color initialColor;
  final ValueChanged<Color> onChanged;

  @override
  State<HslColorPicker> createState() => _HslColorPickerState();
}

class _HslColorPickerState extends State<HslColorPicker> {
  late HSLColor _hsl = HSLColor.fromColor(widget.initialColor);

  void _update(HSLColor next) {
    setState(() => _hsl = next);
    widget.onChanged(next.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsl.toColor();
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(
            hex,
            style: TextStyle(
              color: _hsl.lightness > 0.6 ? Colors.black87 : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _GradientSlider(
          label: 'التدرّج اللوني',
          value: _hsl.hue,
          min: 0,
          max: 360,
          gradientColors: List.generate(7, (i) => HSLColor.fromAHSL(1, i * 60.0, 1, 0.5).toColor()),
          onChanged: (v) => _update(_hsl.withHue(v)),
        ),
        _GradientSlider(
          label: 'التشبّع',
          value: _hsl.saturation,
          min: 0,
          max: 1,
          gradientColors: [_hsl.withSaturation(0).toColor(), _hsl.withSaturation(1).toColor()],
          onChanged: (v) => _update(_hsl.withSaturation(v)),
        ),
        _GradientSlider(
          label: 'الإضاءة',
          value: _hsl.lightness,
          min: 0,
          max: 1,
          gradientColors: [
            _hsl.withLightness(0).toColor(),
            _hsl.withLightness(0.5).toColor(),
            _hsl.withLightness(1).toColor(),
          ],
          onChanged: (v) => _update(_hsl.withLightness(v)),
        ),
      ],
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.gradientColors,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final List<Color> gradientColors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 14,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
