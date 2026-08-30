import 'azkar_item.dart';

/// باب من أبواب حصن المسلم (مثل "أذكار الصباح والمساء")، ويضم أدعيته.
class AzkarCategory {
  const AzkarCategory({required this.id, required this.title, required this.items});

  final int id;
  final String title;
  final List<AzkarItem> items;

  factory AzkarCategory.fromJson(int id, Map<String, Object?> json) => AzkarCategory(
        id: id,
        title: json['title']! as String,
        items: (json['items']! as List<Object?>)
            .map((e) => AzkarItem.fromJson(e! as Map<String, Object?>))
            .toList(),
      );
}
