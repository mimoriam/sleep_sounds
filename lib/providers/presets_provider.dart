import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mix_preset.dart';

class PresetsProvider extends ChangeNotifier {
  static const String _keyPresets = 'saved_mix_presets';
  final SharedPreferences _prefs;
  List<MixPreset> _presets = [];

  PresetsProvider(this._prefs) {
    _loadPresets();
  }

  List<MixPreset> get presets => List.unmodifiable(_presets);

  void _loadPresets() {
    try {
      final jsonString = _prefs.getString(_keyPresets);
      if (jsonString != null) {
        final List<dynamic> list = jsonDecode(jsonString);
        _presets = list
            .map((item) => MixPreset.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading presets: $e');
    }
    notifyListeners();
  }

  Future<bool> savePreset({
    required String name,
    required String mainSoundId,
    required List<LayerConfig> layers,
    double masterVolume = 0.70,
  }) async {
    if (_presets.length >= 15) {
      return false; // Max preset limit
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newPreset = MixPreset(
      id: id,
      name: name.trim().isEmpty ? 'My Mix ${_presets.length + 1}' : name.trim(),
      mainSoundId: mainSoundId,
      layers: layers,
      masterVolume: masterVolume,
    );

    _presets.add(newPreset);
    await _saveToStorage();
    notifyListeners();
    return true;
  }

  Future<void> deletePreset(String id) async {
    _presets.removeWhere((p) => p.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> renamePreset(String id, String newName) async {
    final index = _presets.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final old = _presets[index];
      _presets[index] = MixPreset(
        id: old.id,
        name: newName.trim(),
        mainSoundId: old.mainSoundId,
        layers: old.layers,
        masterVolume: old.masterVolume,
      );
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> _saveToStorage() async {
    final jsonList = _presets.map((p) => p.toJson()).toList();
    await _prefs.setString(_keyPresets, jsonEncode(jsonList));
  }
}
