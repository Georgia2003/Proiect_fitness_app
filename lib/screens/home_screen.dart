import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura_fit/blocs/user/user_bloc.dart';
import 'package:aura_fit/blocs/workout/workout_bloc.dart';
import 'package:aura_fit/blocs/nutrition/nutrition_bloc.dart';
import 'package:aura_fit/screens/profile_screen.dart';
import 'package:aura_fit/screens/workout_screen.dart';
import 'package:aura_fit/screens/nutrition_screen.dart';
import 'package:aura_fit/screens/avatar_creator_screen.dart';
import 'package:aura_fit/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // All four screens are kept alive in the IndexedStack.
  // AvatarCreatorScreen loads the RPM WebView immediately so it is ready
  // when the user first taps the Avatar tab.
  static const _pages = [
    ProfileScreen(),
    WorkoutScreen(),
    NutritionScreen(),
    AvatarCreatorScreen(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>()
        .add(const UserSubscriptionRequested());
    context.read<WorkoutBloc>()
        .add(const WorkoutSubscriptionRequested());
    context.read<NutritionBloc>()
      ..add(const NutritionTodaySubscriptionRequested())
      ..add(const NutritionHistorySubscriptionRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index:    _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _NavBar(
        currentIndex: _currentIndex,
        onTap:        (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({required this.currentIndex, required this.onTap});

  final int               currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:  kSurface,
        border: Border(
          top: BorderSide(color: kIndigo.withValues(alpha: 0.15)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap:        onTap,
        items: const [
          BottomNavigationBarItem(
            icon:       Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label:      'Profile',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label:      'Workout',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label:      'Nutrition',
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.face_outlined),
            activeIcon: Icon(Icons.face),
            label:      'Avatar',
          ),
        ],
      ),
    );
  }
}