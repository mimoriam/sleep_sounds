import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleep_sounds/models/sound_model.dart';
import 'package:sleep_sounds/providers/favorites_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesProvider Tests', () {
    late FavoritesProvider favoritesProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial favorites list should be empty', () async {
      final prefs = await SharedPreferences.getInstance();
      favoritesProvider = FavoritesProvider(prefs);
      expect(favoritesProvider.favoriteIds, isEmpty);
      expect(favoritesProvider.favoriteSounds, isEmpty);
    });

    test('Toggling favorite adds and removes sound ID correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      favoritesProvider = FavoritesProvider(prefs);
      
      const soundId = 'wave';
      expect(favoritesProvider.isFavorite(soundId), false);

      await favoritesProvider.toggleFavorite(soundId);
      expect(favoritesProvider.isFavorite(soundId), true);
      expect(favoritesProvider.favoriteSounds.length, 1);
      expect(favoritesProvider.favoriteSounds.first.id, soundId);

      await favoritesProvider.toggleFavorite(soundId);
      expect(favoritesProvider.isFavorite(soundId), false);
      expect(favoritesProvider.favoriteSounds, isEmpty);
    });
  });

  group('SoundRegistry Tests', () {
    test('SoundRegistry returns valid sound for ID', () {
      final sound = SoundRegistry.getByIdOrNull('wave');
      expect(sound, isNotNull);
      expect(sound!.title, 'Ocean Waves');
    });

    test('SoundRegistry returns null for invalid ID', () {
      final sound = SoundRegistry.getByIdOrNull('non_existent_id');
      expect(sound, isNull);
    });
  });
}
