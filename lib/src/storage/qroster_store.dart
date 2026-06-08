import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_data.dart';

abstract class QrosterStore {
  Future<AppData> load();
  Future<void> save(AppData data);
}

class SharedPreferencesQrosterStore implements QrosterStore {
  SharedPreferencesQrosterStore(this._preferences);

  static const _stateKey = 'qroster_state_v1';

  final SharedPreferences _preferences;

  @override
  Future<AppData> load() async {
    final raw = _preferences.getString(_stateKey);
    if (raw == null || raw.trim().isEmpty) {
      return AppData.empty();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppData.fromJson(decoded);
    } catch (_) {
      return AppData.empty();
    }
  }

  @override
  Future<void> save(AppData data) async {
    await _preferences.setString(_stateKey, jsonEncode(data.toJson()));
  }
}

class MemoryQrosterStore implements QrosterStore {
  MemoryQrosterStore([AppData? initialData]) : _data = initialData;

  AppData? _data;

  @override
  Future<AppData> load() async => _data ?? AppData.empty();

  @override
  Future<void> save(AppData data) async {
    _data = data;
  }
}
