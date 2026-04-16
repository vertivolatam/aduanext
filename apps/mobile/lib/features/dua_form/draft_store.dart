/// Local draft persistence.
///
/// Abstracted so:
///   * Widget tests swap in the in-memory implementation without
///     touching SharedPreferences.
///   * The web build uses `SharedPreferences` (localStorage).
///   * Native builds (deferred) can plug `SharedPreferences` or a
///     sqlite adapter interchangeably.
///
/// Only one draft is kept at a time — the form is a wizard, not a
/// multi-document editor. When the agent clicks "Nueva DUA" the
/// existing draft is archived (persisted with a new key) in a
/// separate ticket; for now a second call overwrites.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'dua_form_state.dart';

abstract class DuaDraftStore {
  Future<DuaDraft?> load();
  Future<void> save(DuaDraft draft);
  Future<void> clear();
}

/// Persistent store backed by `SharedPreferences` (localStorage on web).
class SharedPrefsDraftStore implements DuaDraftStore {
  static const String _key = 'aduanext.dua_draft';

  @override
  Future<DuaDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return DuaDraft.fromJson(decoded);
    } catch (_) {
      // Corrupt / legacy payload — drop it so a restart doesn't
      // wedge the form on boot.
      await prefs.remove(_key);
    }
    return null;
  }

  @override
  Future<void> save(DuaDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// In-memory store for tests.
class InMemoryDraftStore implements DuaDraftStore {
  DuaDraft? _cached;

  /// How many times `save` has been called — useful for tests that
  /// assert autosave fires on a timer.
  int saveCount = 0;

  InMemoryDraftStore([this._cached]);

  @override
  Future<DuaDraft?> load() async => _cached;

  @override
  Future<void> save(DuaDraft draft) async {
    _cached = draft;
    saveCount++;
  }

  @override
  Future<void> clear() async {
    _cached = null;
  }
}
