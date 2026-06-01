import 'package:aura_fit/database/app_database.dart';
import 'package:drift/drift.dart';

class WorkoutRepository {
  WorkoutRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  Stream<List<Workout>> watchAllWorkouts()    => _db.watchAllWorkouts();
  Stream<List<Workout>> watchTodaysWorkouts() => _db.watchTodaysWorkouts();

  Future<void> logSet({
    required String exerciseName,
    required int    sets,
    required int    reps,
    required double weight,
  }) =>
      _db.insertWorkout(
        WorkoutsCompanion(
          exerciseName: Value(exerciseName),
          sets:         Value(sets),
          reps:         Value(reps),
          weight:       Value(weight),
          timestamp:    Value(DateTime.now()),
          isSynced:     const Value(false),
        ),
      );

  Future<void> deleteWorkout(int id) => _db.deleteWorkoutById(id);
}