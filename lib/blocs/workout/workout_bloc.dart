import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura_fit/database/app_database.dart';
import 'package:aura_fit/repositories/workout_repository.dart';

// ─── Avatar State ─────────────────────────────────────────────────────────────

enum AvatarState { idle, exercising, resting }

// ─── Predefined Exercises ─────────────────────────────────────────────────────

class ExerciseDefinition extends Equatable {
  const ExerciseDefinition({
    required this.name,
    required this.icon,
    required this.isBodyweight,
  });

  final String  name;
  final String  icon;
  final bool    isBodyweight;

  @override
  List<Object?> get props => [name];
}

const kExercises = <ExerciseDefinition>[
  ExerciseDefinition(name: 'Push-ups',  icon: '💪', isBodyweight: true),
  ExerciseDefinition(name: 'Squats',    icon: '🦵', isBodyweight: true),
  ExerciseDefinition(name: 'Pull-ups',  icon: '🏋️', isBodyweight: true),
  ExerciseDefinition(name: 'Bench Press', icon: '🪑', isBodyweight: false),
  ExerciseDefinition(name: 'Deadlift',  icon: '⚡', isBodyweight: false),
  ExerciseDefinition(name: 'Overhead Press', icon: '🔝', isBodyweight: false),
];

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();
  @override
  List<Object?> get props => [];
}

class WorkoutSubscriptionRequested extends WorkoutEvent {
  const WorkoutSubscriptionRequested();
}

class WorkoutExerciseSelected extends WorkoutEvent {
  const WorkoutExerciseSelected(this.exercise);
  final ExerciseDefinition exercise;
  @override
  List<Object?> get props => [exercise];
}

class WorkoutTimerStarted extends WorkoutEvent {
  const WorkoutTimerStarted();
}

class WorkoutTimerStopped extends WorkoutEvent {
  const WorkoutTimerStopped();
}

class WorkoutTimerReset extends WorkoutEvent {
  const WorkoutTimerReset();
}

class _WorkoutTimerTicked extends WorkoutEvent {
  const _WorkoutTimerTicked(this.elapsed);
  final int elapsed;
  @override
  List<Object?> get props => [elapsed];
}

class WorkoutRestStarted extends WorkoutEvent {
  const WorkoutRestStarted(this.seconds);
  final int seconds;
  @override
  List<Object?> get props => [seconds];
}

class _WorkoutRestTicked extends WorkoutEvent {
  const _WorkoutRestTicked(this.remaining);
  final int remaining;
  @override
  List<Object?> get props => [remaining];
}

class WorkoutSetLogged extends WorkoutEvent {
  const WorkoutSetLogged({
    required this.sets,
    required this.reps,
    required this.weight,
  });
  final int    sets;
  final int    reps;
  final double weight;
  @override
  List<Object?> get props => [sets, reps, weight];
}

class WorkoutSetDeleted extends WorkoutEvent {
  const WorkoutSetDeleted(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

// ─── State ────────────────────────────────────────────────────────────────────

class WorkoutState extends Equatable {
  const WorkoutState({
    this.todaysWorkouts       = const [],
    this.selectedExercise,
    this.avatarState          = AvatarState.idle,
    this.elapsedSeconds       = 0,
    this.isTimerRunning       = false,
    this.restRemainingSeconds = 0,
    this.isResting            = false,
    this.status               = WorkoutStatus.initial,
  });

  final List<Workout>        todaysWorkouts;
  final ExerciseDefinition?  selectedExercise;
  final AvatarState          avatarState;
  final int                  elapsedSeconds;
  final bool                 isTimerRunning;
  final int                  restRemainingSeconds;
  final bool                 isResting;
  final WorkoutStatus        status;

  WorkoutState copyWith({
    List<Workout>?        todaysWorkouts,
    ExerciseDefinition?   selectedExercise,
    AvatarState?          avatarState,
    int?                  elapsedSeconds,
    bool?                 isTimerRunning,
    int?                  restRemainingSeconds,
    bool?                 isResting,
    WorkoutStatus?        status,
  }) =>
      WorkoutState(
        todaysWorkouts:       todaysWorkouts       ?? this.todaysWorkouts,
        selectedExercise:     selectedExercise     ?? this.selectedExercise,
        avatarState:          avatarState          ?? this.avatarState,
        elapsedSeconds:       elapsedSeconds       ?? this.elapsedSeconds,
        isTimerRunning:       isTimerRunning       ?? this.isTimerRunning,
        restRemainingSeconds: restRemainingSeconds ?? this.restRemainingSeconds,
        isResting:            isResting            ?? this.isResting,
        status:               status               ?? this.status,
      );

  String get formattedElapsed {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds  % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  List<Object?> get props => [
        todaysWorkouts,
        selectedExercise,
        avatarState,
        elapsedSeconds,
        isTimerRunning,
        restRemainingSeconds,
        isResting,
        status,
      ];
}

enum WorkoutStatus { initial, loading, loaded, error }

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  WorkoutBloc({required WorkoutRepository repository})
      : _repo = repository,
        super(const WorkoutState()) {
    on<WorkoutSubscriptionRequested>(_onSubscription);
    on<WorkoutExerciseSelected>(_onExerciseSelected);
    on<WorkoutTimerStarted>(_onTimerStarted);
    on<WorkoutTimerStopped>(_onTimerStopped);
    on<WorkoutTimerReset>(_onTimerReset);
    on<_WorkoutTimerTicked>(_onTimerTicked);
    on<WorkoutRestStarted>(_onRestStarted);
    on<_WorkoutRestTicked>(_onRestTicked);
    on<WorkoutSetLogged>(_onSetLogged);
    on<WorkoutSetDeleted>(_onSetDeleted);
  }

  final WorkoutRepository _repo;
  Timer? _exerciseTimer;
  Timer? _restTimer;

  Future<void> _onSubscription(
    WorkoutSubscriptionRequested event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(state.copyWith(status: WorkoutStatus.loading));
    await emit.onEach<List<Workout>>(
      _repo.watchTodaysWorkouts(),
      onData:  (list)  => emit(state.copyWith(todaysWorkouts: list, status: WorkoutStatus.loaded)),
      onError: (_, __) => emit(state.copyWith(status: WorkoutStatus.error)),
    );
  }

  void _onExerciseSelected(
    WorkoutExerciseSelected event,
    Emitter<WorkoutState> emit,
  ) {
    _stopExerciseTimer();
    _stopRestTimer();
    emit(state.copyWith(
      selectedExercise:     event.exercise,
      avatarState:          AvatarState.idle,
      elapsedSeconds:       0,
      isTimerRunning:       false,
      isResting:            false,
      restRemainingSeconds: 0,
    ));
  }

  void _onTimerStarted(WorkoutTimerStarted event, Emitter<WorkoutState> emit) {
    if (state.isTimerRunning) return;
    emit(state.copyWith(isTimerRunning: true, avatarState: AvatarState.exercising));
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(_WorkoutTimerTicked(state.elapsedSeconds + 1));
    });
  }

  void _onTimerStopped(WorkoutTimerStopped event, Emitter<WorkoutState> emit) {
    _stopExerciseTimer();
    emit(state.copyWith(isTimerRunning: false, avatarState: AvatarState.idle));
  }

  void _onTimerReset(WorkoutTimerReset event, Emitter<WorkoutState> emit) {
    _stopExerciseTimer();
    emit(state.copyWith(
      isTimerRunning: false,
      elapsedSeconds: 0,
      avatarState:    AvatarState.idle,
    ));
  }

  void _onTimerTicked(
    _WorkoutTimerTicked event,
    Emitter<WorkoutState> emit,
  ) =>
      emit(state.copyWith(elapsedSeconds: event.elapsed));

  void _onRestStarted(WorkoutRestStarted event, Emitter<WorkoutState> emit) {
    _stopExerciseTimer();
    _stopRestTimer();
    emit(state.copyWith(
      isTimerRunning:       false,
      isResting:            true,
      restRemainingSeconds: event.seconds,
      avatarState:          AvatarState.resting,
    ));
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.restRemainingSeconds - 1;
      if (remaining <= 0) {
        _stopRestTimer();
        add(const _WorkoutRestTicked(0));
      } else {
        add(_WorkoutRestTicked(remaining));
      }
    });
  }

  void _onRestTicked(
    _WorkoutRestTicked event,
    Emitter<WorkoutState> emit,
  ) {
    if (event.remaining <= 0) {
      emit(state.copyWith(
        isResting:            false,
        restRemainingSeconds: 0,
        avatarState:          AvatarState.idle,
      ));
    } else {
      emit(state.copyWith(restRemainingSeconds: event.remaining));
    }
  }

  Future<void> _onSetLogged(
    WorkoutSetLogged event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state.selectedExercise == null) return;
    await _repo.logSet(
      exerciseName: state.selectedExercise!.name,
      sets:         event.sets,
      reps:         event.reps,
      weight:       event.weight,
    );
  }

  Future<void> _onSetDeleted(
    WorkoutSetDeleted event,
    Emitter<WorkoutState> emit,
  ) async =>
      _repo.deleteWorkout(event.id);

  void _stopExerciseTimer() {
    _exerciseTimer?.cancel();
    _exerciseTimer = null;
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
  }

  @override
  Future<void> close() {
    _stopExerciseTimer();
    _stopRestTimer();
    return super.close();
  }
}