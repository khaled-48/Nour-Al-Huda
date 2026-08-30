import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/azkar_repository.dart';
import '../../domain/azkar_category.dart';

final azkarRepositoryProvider = Provider<AzkarRepository>((ref) => const AzkarRepository());

final azkarCategoriesProvider = FutureProvider<Map<int, AzkarCategory>>((ref) {
  return ref.watch(azkarRepositoryProvider).getAllCategories();
});
