import 'package:aura_fit/database/app_database.dart';
import 'package:drift/drift.dart';

class NutritionRepository {
  NutritionRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  Stream<List<NutritionLog>> watchTodaysNutrition()  => _db.watchTodaysNutrition();
  Stream<List<NutritionLog>> watchNutritionLast7Days() => _db.watchNutritionLast7Days();

  Future<void> addEntry({
    required String foodName,
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
  }) =>
      _db.insertNutrition(
        NutritionLogsCompanion(
          foodName: Value(foodName),
          calories: Value(calories),
          protein:  Value(protein),
          carbs:    Value(carbs),
          fats:     Value(fats),
          date:     Value(DateTime.now()),
          isSynced: const Value(false),
        ),
      );

  Future<void> deleteEntry(int id) => _db.deleteNutritionById(id);
}