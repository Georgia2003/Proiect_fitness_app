import 'package:aura_fit/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:dio/dio.dart';

class UserRepository {
  UserRepository({required AppDatabase db, Dio? dio})
      : _db  = db,
        _dio = dio ?? Dio();

  final AppDatabase _db;
  final Dio         _dio;

  // ── Reactive stream — UI subscribes to this ─────────────────────────────────
  Stream<User?> watchUser() => _db.watchFirstUser();

  // ── Read ────────────────────────────────────────────────────────────────────
  Future<User?> getUser() => _db.getFirstUser();

  // ── Write (local-first, mark unsynced, background sync) ─────────────────────
  Future<void> saveUser(UsersCompanion companion) async {
    await _db.upsertUser(companion);
    _syncUserInBackground();
  }

  // ── Background sync stub ────────────────────────────────────────────────────
  void _syncUserInBackground() {
    Future.microtask(() async {
      try {
        final user = await _db.getFirstUser();
        if (user == null || user.isSynced) return;

        await _dio.post(
          'https://api.aurafit.local/users/${user.id}',
          data: {
            'name': user.name,
            'age': user.age,
            'gender': user.gender,
            'height': user.height,
            'weight': user.weight,
            'bodyFat': user.bodyFat,
          },
        );

        await _db.upsertUser(
          UsersCompanion(
            id:       Value(user.id),
            name:     Value(user.name),
            age:      Value(user.age),
            gender:   Value(user.gender),
            height:   Value(user.height),
            weight:   Value(user.weight),
            bodyFat:  Value(user.bodyFat),
            isSynced: const Value(true),
          ),
        );
      } catch (_) {
        // Network unavailable — local data remains, sync retried next save.
      }
    });
  }
}