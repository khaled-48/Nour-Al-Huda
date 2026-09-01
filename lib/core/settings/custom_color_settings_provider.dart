import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'custom_color_settings.dart';

const _prefEnabled = 'pref_custom_colors_enabled';
const _prefText = 'pref_custom_color_text';
const _prefBackground = 'pref_custom_color_background';
const _prefDate = 'pref_custom_color_date';
const _prefClock = 'pref_custom_color_clock';

class CustomColorSettingsNotifier extends StateNotifier<CustomColorSettings> {
  CustomColorSettingsNotifier() : super(const CustomColorSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = CustomColorSettings(
      enabled: prefs.getBool(_prefEnabled) ?? false,
      textColor: _readColor(prefs, _prefText),
      backgroundColor: _readColor(prefs, _prefBackground),
      dateColor: _readColor(prefs, _prefDate),
      clockColor: _readColor(prefs, _prefClock),
    );
  }

  Color? _readColor(SharedPreferences prefs, String key) {
    final value = prefs.getInt(key);
    return value == null ? null : Color(value);
  }

  Future<void> setEnabled(bool value) async {
    state = CustomColorSettings(
      enabled: value,
      textColor: state.textColor,
      backgroundColor: state.backgroundColor,
      dateColor: state.dateColor,
      clockColor: state.clockColor,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, value);
  }

  Future<void> setTextColor(Color? color) async {
    state = CustomColorSettings(
      enabled: state.enabled,
      textColor: color,
      backgroundColor: state.backgroundColor,
      dateColor: state.dateColor,
      clockColor: state.clockColor,
    );
    await _persistColor(_prefText, color);
  }

  Future<void> setBackgroundColor(Color? color) async {
    state = CustomColorSettings(
      enabled: state.enabled,
      textColor: state.textColor,
      backgroundColor: color,
      dateColor: state.dateColor,
      clockColor: state.clockColor,
    );
    await _persistColor(_prefBackground, color);
  }

  Future<void> setDateColor(Color? color) async {
    state = CustomColorSettings(
      enabled: state.enabled,
      textColor: state.textColor,
      backgroundColor: state.backgroundColor,
      dateColor: color,
      clockColor: state.clockColor,
    );
    await _persistColor(_prefDate, color);
  }

  Future<void> setClockColor(Color? color) async {
    state = CustomColorSettings(
      enabled: state.enabled,
      textColor: state.textColor,
      backgroundColor: state.backgroundColor,
      dateColor: state.dateColor,
      clockColor: color,
    );
    await _persistColor(_prefClock, color);
  }

  Future<void> resetAll() async {
    state = const CustomColorSettings(enabled: true);
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_prefText),
      prefs.remove(_prefBackground),
      prefs.remove(_prefDate),
      prefs.remove(_prefClock),
    ]);
  }

  Future<void> _persistColor(String key, Color? color) async {
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, color.toARGB32());
    }
  }
}

final customColorSettingsProvider =
    StateNotifierProvider<CustomColorSettingsNotifier, CustomColorSettings>((
      ref,
    ) {
      return CustomColorSettingsNotifier();
    });
