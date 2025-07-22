import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/journal_entry.dart';

class JournalProvider extends ChangeNotifier {
  static const String _boxName = 'journal_entries';
  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  JournalProvider() {
    loadEntries();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final box = await Hive.openBox<JournalEntry>(_boxName);
      _entries = box.values.toList();
    } catch (e) {
      _error = 'Failed to load entries: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(JournalEntry entry) async {
    try {
      final box = await Hive.openBox<JournalEntry>(_boxName);
      await box.put(entry.id, entry);
      _entries = box.values.toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add entry: $e';
      notifyListeners();
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    try {
      final box = await Hive.openBox<JournalEntry>(_boxName);
      await box.put(entry.id, entry);
      _entries = box.values.toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update entry: $e';
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final box = await Hive.openBox<JournalEntry>(_boxName);
      await box.delete(id);
      _entries = box.values.toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete entry: $e';
      notifyListeners();
    }
  }

  List<JournalEntry> filterEntries({DateTime? date, String? weatherCondition}) {
    return _entries.where((entry) {
      final matchesDate = date == null ||
          (entry.date.year == date.year &&
              entry.date.month == date.month &&
              entry.date.day == date.day);
      final matchesWeather = weatherCondition == null ||
          entry.weather.condition.toLowerCase() == weatherCondition.toLowerCase();
      return matchesDate && matchesWeather;
    }).toList();
  }
}
