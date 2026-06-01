import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura_fit/database/app_database.dart';
import 'package:aura_fit/repositories/nutrition_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class NutritionEvent extends Equatable {
  const NutritionEvent();
  @override
  List<Object?> get props => [];
}

class NutritionTodaySubscriptionRequested extends NutritionEvent {
  const NutritionTodaySubscriptionRequested();
}

class NutritionHistorySubscriptionRequested extends NutritionEvent {
  const NutritionHistorySubscriptionRequested();
}

class NutritionEntryAdded extends NutritionEvent {
  const NutritionEntryAdded({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  @override
  List<Object?> get props => [foodName, calories, protein, carbs, fats];
}

class NutritionEntryDeleted extends NutritionEvent {
  const NutritionEntryDeleted(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

// ─── State ────────────────────────────────────────────────────────────────────

class NutritionState extends Equatable {
  const NutritionState({
    this.todaysLogs    = const [],
    this.historyLogs   = const [],
    this.totalCalories = 0,
    this.totalProtein  = 0,
    this.totalCarbs    = 0,
    this.totalFats     = 0,
    this.status        = NutritionStatus.initial,
  });

  final List<NutritionLog> todaysLogs;
  final List<NutritionLog> historyLogs;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final NutritionStatus status;

  NutritionState copyWith({
    List<NutritionLog>? todaysLogs,
    List<NutritionLog>? historyLogs,
    double?             totalCalories,
    double?             totalProtein,
    double?             totalCarbs,
    double?             totalFats,
    NutritionStatus?    status,
  }) =>
      NutritionState(
        todaysLogs:    todaysLogs    ?? this.todaysLogs,
        historyLogs:   historyLogs   ?? this.historyLogs,
        totalCalories: totalCalories ?? this.totalCalories,
        totalProtein:  totalProtein  ?? this.totalProtein,
        totalCarbs:    totalCarbs    ?? this.totalCarbs,
        totalFats:     totalFats     ?? this.totalFats,
        status:        status        ?? this.status,
      );

  @override
  List<Object?> get props => [
        todaysLogs,
        historyLogs,
        totalCalories,
        totalProtein,
        totalCarbs,
        totalFats,
        status,
      ];
}

enum NutritionStatus { initial, loading, loaded, error }

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  NutritionBloc({required NutritionRepository repository})
      : _repo = repository,
        super(const NutritionState()) {
    on<NutritionTodaySubscriptionRequested>(_onTodaySubscription);
    on<NutritionHistorySubscriptionRequested>(_onHistorySubscription);
    on<NutritionEntryAdded>(_onEntryAdded);
    on<NutritionEntryDeleted>(_onEntryDeleted);
  }

  final NutritionRepository _repo;

  Future<void> _onTodaySubscription(
    NutritionTodaySubscriptionRequested event,
    Emitter<NutritionState> emit,
  ) async {
    emit(state.copyWith(status: NutritionStatus.loading));
    await emit.onEach<List<NutritionLog>>(
      _repo.watchTodaysNutrition(),
      onData: (logs) {
        double cal = 0, pro = 0, carb = 0, fat = 0;
        for (final l in logs) {
          cal  += l.calories;
          pro  += l.protein;
          carb += l.carbs;
          fat  += l.fats;
        }
        emit(state.copyWith(
          todaysLogs:    logs,
          totalCalories: cal,
          totalProtein:  pro,
          totalCarbs:    carb,
          totalFats:     fat,
          status:        NutritionStatus.loaded,
        ));
      },
      onError: (_, __) => emit(state.copyWith(status: NutritionStatus.error)),
    );
  }

  Future<void> _onHistorySubscription(
    NutritionHistorySubscriptionRequested event,
    Emitter<NutritionState> emit,
  ) async {
    await emit.onEach<List<NutritionLog>>(
      _repo.watchNutritionLast7Days(),
      onData:  (logs)  => emit(state.copyWith(historyLogs: logs)),
      onError: (_, __) {},
    );
  }

  Future<void> _onEntryAdded(
    NutritionEntryAdded event,
    Emitter<NutritionState> emit,
  ) async =>
      _repo.addEntry(
        foodName: event.foodName,
        calories: event.calories,
        protein:  event.protein,
        carbs:    event.carbs,
        fats:     event.fats,
      );

  Future<void> _onEntryDeleted(
    NutritionEntryDeleted event,
    Emitter<NutritionState> emit,
  ) async =>
      _repo.deleteEntry(event.id);
}