/// دعاء أو ذكر واحد ضمن باب من أبواب حصن المسلم، مع مرجعه إن وُجد.
class AzkarItem {
  const AzkarItem({required this.text, this.footnote});

  final String text;
  final String? footnote;

  factory AzkarItem.fromJson(Map<String, Object?> json) => AzkarItem(
        text: json['text']! as String,
        footnote: json['footnote'] as String?,
      );
}
