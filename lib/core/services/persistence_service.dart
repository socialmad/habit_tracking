import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';

class PersistenceService {
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keySortOption = 'sort_option';
  static const String _keyFilterFrequency = 'filter_frequency';
  static const String _keyFilterArchived = 'filter_archived';
  static const String _keyFilterStreak = 'filter_streak';

  final SharedPreferences _prefs;

  PersistenceService(this._prefs);

  // Search History
  List<String> getRecentSearches() {
    return _prefs.getStringList(_keyRecentSearches) ?? [];
  }

  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    final searches = getRecentSearches();
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 5) searches.removeLast();
    await _prefs.setStringList(_keyRecentSearches, searches);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_keyRecentSearches);
  }

  // Sort Preference
  HabitSortOption getSortOption() {
    final index = _prefs.getInt(_keySortOption) ?? 0;
    if (index >= 0 && index < HabitSortOption.values.length) {
      return HabitSortOption.values[index];
    }
    return HabitSortOption.recentlyAdded;
  }

  Future<void> saveSortOption(HabitSortOption option) async {
    await _prefs.setInt(_keySortOption, option.index);
  }

  // Filter Preferences
  Map<String, dynamic> getFilterPreferences() {
    return {
      'frequency': _prefs.getString(_keyFilterFrequency),
      'archived': _prefs.getBool(_keyFilterArchived),
      'onlyActiveStreaks': _prefs.getBool(_keyFilterStreak),
    };
  }

  Future<void> saveFilterPreferences({
    String? frequency,
    bool? archived,
    bool? onlyActiveStreaks,
  }) async {
    if (frequency != null) {
      await _prefs.setString(_keyFilterFrequency, frequency);
    } else {
      await _prefs.remove(_keyFilterFrequency);
    }

    if (archived != null) {
      await _prefs.setBool(_keyFilterArchived, archived);
    } else {
      await _prefs.remove(_keyFilterArchived);
    }

    if (onlyActiveStreaks != null) {
      await _prefs.setBool(_keyFilterStreak, onlyActiveStreaks);
    } else {
      await _prefs.remove(_keyFilterStreak);
    }
  }
}
