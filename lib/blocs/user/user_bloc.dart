import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura_fit/database/app_database.dart';
import 'package:aura_fit/repositories/user_repository.dart';
import 'package:drift/drift.dart' show Value;

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object?> get props => [];
}

class UserSubscriptionRequested extends UserEvent {
  const UserSubscriptionRequested();
}

class UserUpdated extends UserEvent {
  const UserUpdated({
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.bodyFat,
    this.id,
  });

  final int?    id;
  final String  name;
  final int     age;
  final String  gender;
  final double  height;
  final double  weight;
  final double  bodyFat;

  @override
  List<Object?> get props => [id, name, age, gender, height, weight, bodyFat];
}

// ─── State ────────────────────────────────────────────────────────────────────

class UserState extends Equatable {
  const UserState({
    this.user,
    this.bmr            = 0,
    this.calorieTarget  = 0,
    this.proteinTarget  = 0,
    this.carbsTarget    = 0,
    this.fatsTarget     = 0,
    this.status         = UserStatus.initial,
  });

  final User?       user;
  final double      bmr;
  final double      calorieTarget;
  final double      proteinTarget;
  final double      carbsTarget;
  final double      fatsTarget;
  final UserStatus  status;

  UserState copyWith({
    User?       user,
    double?     bmr,
    double?     calorieTarget,
    double?     proteinTarget,
    double?     carbsTarget,
    double?     fatsTarget,
    UserStatus? status,
  }) =>
      UserState(
        user:           user           ?? this.user,
        bmr:            bmr            ?? this.bmr,
        calorieTarget:  calorieTarget  ?? this.calorieTarget,
        proteinTarget:  proteinTarget  ?? this.proteinTarget,
        carbsTarget:    carbsTarget    ?? this.carbsTarget,
        fatsTarget:     fatsTarget     ?? this.fatsTarget,
        status:         status         ?? this.status,
      );

  @override
  List<Object?> get props =>
      [user, bmr, calorieTarget, proteinTarget, carbsTarget, fatsTarget, status];
}

enum UserStatus { initial, loading, loaded, error }

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({required UserRepository repository})
      : _repo = repository,
        super(const UserState()) {
    on<UserSubscriptionRequested>(_onSubscriptionRequested);
    on<UserUpdated>(_onUserUpdated);
  }

  final UserRepository _repo;
  StreamSubscription<User?>? _sub;

  Future<void> _onSubscriptionRequested(
    UserSubscriptionRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(status: UserStatus.loading));
    await emit.onEach<User?>(
      _repo.watchUser(),
      onData: (user) {
        if (user == null) {
          emit(state.copyWith(status: UserStatus.loaded));
          return;
        }
        final macros = _computeMacros(user);
        emit(
          state.copyWith(
            user:          user,
            bmr:           macros.$1,
            calorieTarget: macros.$2,
            proteinTarget: macros.$3,
            carbsTarget:   macros.$4,
            fatsTarget:    macros.$5,
            status:        UserStatus.loaded,
          ),
        );
      },
      onError: (_, __) => emit(state.copyWith(status: UserStatus.error)),
    );
  }

  Future<void> _onUserUpdated(
    UserUpdated event,
    Emitter<UserState> emit,
  ) async {
    await _repo.saveUser(
      UsersCompanion(
        id:      event.id != null ? Value(event.id!) : const Value.absent(),
        name:    Value(event.name),
        age:     Value(event.age),
        gender:  Value(event.gender),
        height:  Value(event.height),
        weight:  Value(event.weight),
        bodyFat: Value(event.bodyFat),
      ),
    );
  }

  /// Returns (bmr, calories, protein, carbs, fats).
  /// Mifflin-St Jeor: male   = 10w + 6.25h − 5a + 5
  ///                  female = 10w + 6.25h − 5a − 161
  (double, double, double, double, double) _computeMacros(User u) {
    final offset = u.gender.toLowerCase() == 'female' ? -161.0 : 5.0;
    final bmr = 10 * u.weight + 6.25 * u.height - 5 * u.age + offset;
    return (
      bmr,
      bmr * 1.2,
      u.weight * 2.0,
      u.weight * 4.0,
      u.weight * 1.0,
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}