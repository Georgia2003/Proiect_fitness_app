import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Users extends Table {
  IntColumn get id     => integer().autoIncrement()();
  TextColumn get name  => text().withLength(min: 1, max: 100)();
  IntColumn  get age   => integer()();
  TextColumn get gender => text().withLength(min: 1, max: 10)();
  RealColumn get height  => real()(); // cm
  RealColumn get weight  => real()(); // kg
  RealColumn get bodyFat => real()(); // %
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
}

class Workouts extends Table {
  IntColumn  get id           => integer().autoIncrement()();
  TextColumn get exerciseName => text()();
  IntColumn  get sets         => integer()();
  IntColumn  get reps         => integer()();
  RealColumn get weight       => real()(); // kg (0 for bodyweight)
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isSynced     =>
      boolean().withDefault(const Constant(false))();
}

class NutritionLogs extends Table {
  IntColumn  get id       => integer().autoIncrement()();
  TextColumn get foodName => text()();
  RealColumn get calories => real()();
  RealColumn get protein  => real()(); // g
  RealColumn get carbs    => real()(); // g
  RealColumn get fats     => real()(); // g
  DateTimeColumn get date => dateTime()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Users, Workouts, NutritionLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Users ──────────────────────────────────────────────────────────────────

  Stream<User?> watchFirstUser() {
    return (select(users)..limit(1)).watchSingleOrNull();
  }

  Future<User?> getFirstUser() {
    return (select(users)..limit(1)).getSingleOrNull();
  }

  Future<int> upsertUser(UsersCompanion user) {
    return into(users).insertOnConflictUpdate(user);
  }

  // ── Workouts ───────────────────────────────────────────────────────────────

  Stream<List<Workout>> watchAllWorkouts() {
    return (select(workouts)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  Stream<List<Workout>> watchTodaysWorkouts() {
    final now         = DateTime.now();
    final startOfDay  = DateTime(now.year, now.month, now.day);
    final endOfDay    = startOfDay.add(const Duration(days: 1));
    return (select(workouts)
          ..where((t) => t.timestamp.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  Future<int> insertWorkout(WorkoutsCompanion entry) =>
      into(workouts).insert(entry);

  Future<int> deleteWorkoutById(int id) =>
      (delete(workouts)..where((t) => t.id.equals(id))).go();

  // ── Nutrition ──────────────────────────────────────────────────────────────

  Stream<List<NutritionLog>> watchTodaysNutrition() {
    final now        = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay   = startOfDay.add(const Duration(days: 1));
    return (select(nutritionLogs)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay)))
        .watch();
  }

  Stream<List<NutritionLog>> watchNutritionLast7Days() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return (select(nutritionLogs)
          ..where((t) => t.date.isBiggerOrEqualValue(sevenDaysAgo))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<int> insertNutrition(NutritionLogsCompanion entry) =>
      into(nutritionLogs).insert(entry);

  Future<int> deleteNutritionById(int id) =>
      (delete(nutritionLogs)..where((t) => t.id.equals(id))).go();
}

// ─── Connection ───────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'aura_fit.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}