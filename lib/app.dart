import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura_fit/database/app_database.dart';
import 'package:aura_fit/repositories/user_repository.dart';
import 'package:aura_fit/repositories/workout_repository.dart';
import 'package:aura_fit/repositories/nutrition_repository.dart';
import 'package:aura_fit/services/avatar_service.dart';
import 'package:aura_fit/blocs/user/user_bloc.dart';
import 'package:aura_fit/blocs/workout/workout_bloc.dart';
import 'package:aura_fit/blocs/nutrition/nutrition_bloc.dart';
import 'package:aura_fit/screens/home_screen.dart';
import 'package:aura_fit/theme/app_theme.dart';

class AuraFitApp extends StatefulWidget {
  const AuraFitApp({super.key});

  @override
  State<AuraFitApp> createState() => _AuraFitAppState();
}

class _AuraFitAppState extends State<AuraFitApp> {
  late final AppDatabase         _db;
  late final UserRepository      _userRepo;
  late final WorkoutRepository   _workoutRepo;
  late final NutritionRepository _nutritionRepo;
  late final AvatarService       _avatarService;

  @override
  void initState() {
    super.initState();
    _db             = AppDatabase();
    _userRepo       = UserRepository(db: _db);
    _workoutRepo    = WorkoutRepository(db: _db);
    _nutritionRepo  = NutritionRepository(db: _db);
    _avatarService  = AvatarService();
    // Seed the ValueNotifier from SharedPreferences so any
    // ValueListenableBuilder in the tree has the correct initial value.
    _avatarService.init();
  }

  @override
  void dispose() {
    _db.close();
    _avatarService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _userRepo),
        RepositoryProvider.value(value: _workoutRepo),
        RepositoryProvider.value(value: _nutritionRepo),
        RepositoryProvider.value(value: _avatarService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => UserBloc(repository: _userRepo)),
          BlocProvider(create: (_) => WorkoutBloc(repository: _workoutRepo)),
          BlocProvider(create: (_) => NutritionBloc(repository: _nutritionRepo)),
        ],
        child: MaterialApp(
          title:                    'AuraFit',
          debugShowCheckedModeBanner: false,
          theme:                    AppTheme.dark,
          home:                     const HomeScreen(),
        ),
      ),
    );
  }
}