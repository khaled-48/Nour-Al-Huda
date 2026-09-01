import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// اسم المدينة والمسجد كما يكتبهما المستخدم يدوياً (اختياريان)، لعرضهما
/// بجانب مواقيت الصلاة - حساب الأوقات نفسه يبقى بالإحداثيات دائماً، هذان
/// مجرّد تسميتين نصيتين للعرض لا أكثر.
class LocationLabels {
  const LocationLabels({this.cityName, this.mosqueName});

  final String? cityName;
  final String? mosqueName;

  bool get isEmpty =>
      (cityName == null || cityName!.isEmpty) &&
      (mosqueName == null || mosqueName!.isEmpty);
}

class LocationLabelsNotifier extends StateNotifier<LocationLabels> {
  LocationLabelsNotifier() : super(const LocationLabels()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = LocationLabels(
      cityName: prefs.getString(AppConstants.prefCityName),
      mosqueName: prefs.getString(AppConstants.prefMosqueName),
    );
  }

  Future<void> setCityName(String value) async {
    final trimmed = value.trim();
    state = LocationLabels(
      cityName: trimmed.isEmpty ? null : trimmed,
      mosqueName: state.mosqueName,
    );
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(AppConstants.prefCityName);
    } else {
      await prefs.setString(AppConstants.prefCityName, trimmed);
    }
  }

  Future<void> setMosqueName(String value) async {
    final trimmed = value.trim();
    state = LocationLabels(
      cityName: state.cityName,
      mosqueName: trimmed.isEmpty ? null : trimmed,
    );
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(AppConstants.prefMosqueName);
    } else {
      await prefs.setString(AppConstants.prefMosqueName, trimmed);
    }
  }
}

final locationLabelsProvider =
    StateNotifierProvider<LocationLabelsNotifier, LocationLabels>((ref) {
      return LocationLabelsNotifier();
    });
