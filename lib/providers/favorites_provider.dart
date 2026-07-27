import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sound_model.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _keyFavorites = 'favorite_sound_ids';
  final SharedPreferences _prefs;

  Set<String> _favoriteIds = {};

  FavoritesProvider(this._prefs) {
    _loadFavorites();
  }

  List<SoundType> get favoriteSounds {
    return _favoriteIds
        .map((id) => SoundRegistry.getByIdOrNull(id))
        .whereType<SoundType>()
        .toList();
  }

  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void _loadFavorites() {
    final jsonString = _prefs.getString(_keyFavorites);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _favoriteIds = decoded.map((e) => e.toString()).toSet();
      } catch (_) {
        _favoriteIds = {};
      }
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _favoriteIds.clear();
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    await _prefs.setString(_keyFavorites, jsonEncode(_favoriteIds.toList()));
  }
}
