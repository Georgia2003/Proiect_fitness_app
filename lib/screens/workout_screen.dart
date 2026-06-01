import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura_fit/blocs/workout/workout_bloc.dart';
import 'package:aura_fit/widgets/gym_avatar.dart';
import 'package:aura_fit/theme/app_theme.dart';
import 'package:intl/intl.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _setsCtrl   = TextEditingController(text: '3');
  final _repsCtrl   = TextEditingController(text: '10');
  final _weightCtrl = TextEditingController(text: '0');
  int   _restSeconds = 60;

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (ctx, state) => Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: CustomScrollView(
          slivers: [
            // ── Avatar + Timer ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: kSurface,
                  border: Border(
                    bottom: BorderSide(color: kIndigo.withValues(alpha: 0.2)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    GymAvatar(avatarState: state.avatarState, size: 160),
                    const SizedBox(height: 12),
                    _AvatarStateChip(avatarState: state.avatarState),
                    const SizedBox(height: 20),
                    if (!state.isResting) _ExerciseTimer(state: state)
                    else _RestTimer(state: state),
                  ],
                ),
              ),
            ),

            // ── Exercise picker ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'SELECT EXERCISE',
                  style: TextStyle(
                    color:      kAccent.withValues(alpha: 0.8),
                    fontSize:   11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:    3,
                  childAspectRatio:  1.1,
                  crossAxisSpacing:  10,
                  mainAxisSpacing:   10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final ex       = kExercises[i];
                    final selected = state.selectedExercise?.name == ex.name;
                    return GestureDetector(
                      onTap: () => ctx.read<WorkoutBloc>()
                          .add(WorkoutExerciseSelected(ex)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color:        selected ? kAccent.withValues(alpha: 0.15) : kCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? kAccent : kIndigo.withValues(alpha: 0.3),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(ex.icon, style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text(
                              ex.name,
                              style: TextStyle(
                                color:      selected ? kAccent : kTextPrimary,
                                fontSize:   11,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: kExercises.length,
                ),
              ),
            ),

            // ── Log a set ───────────────────────────────────────────────────
            if (state.selectedExercise != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _LogSetCard(
                    exercise:  state.selectedExercise!,
                    setsCtrl:  _setsCtrl,
                    repsCtrl:  _repsCtrl,
                    weightCtrl: _weightCtrl,
                    isBodyweight: state.selectedExercise!.isBodyweight,
                    restSeconds: _restSeconds,
                    onRestChanged: (v) => setState(() => _restSeconds = v),
                    onLog: () {
                      final sets   = int.tryParse(_setsCtrl.text.trim())    ?? 1;
                      final reps   = int.tryParse(_repsCtrl.text.trim())    ?? 1;
                      final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0;
                      ctx.read<WorkoutBloc>()
                        ..add(WorkoutSetLogged(sets: sets, reps: reps, weight: weight))
                        ..add(const WorkoutTimerReset())
                        ..add(WorkoutRestStarted(_restSeconds));
                    },
                  ),
                ),
              ),

            // ── Today's log ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  "TODAY'S LOG",
                  style: TextStyle(
                    color:      kAccent.withValues(alpha: 0.8),
                    fontSize:   11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
            if (state.todaysWorkouts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No sets logged yet today.\nPick an exercise and start training!',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final w = state.todaysWorkouts[i];
                      return Dismissible(
                        key:        Key('workout_${w.id}'),
                        direction:  DismissDirection.endToStart,
                        background: _dismissBg(),
                        onDismissed: (_) => ctx.read<WorkoutBloc>()
                            .add(WorkoutSetDeleted(w.id)),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              width:       40,
                              height:      40,
                              decoration:  BoxDecoration(
                                color:        kIndigo.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  kExercises
                                      .firstWhere(
                                        (e) => e.name == w.exerciseName,
                                        orElse: () => const ExerciseDefinition(
                                          name: '', icon: '⚡', isBodyweight: true),
                                      )
                                      .icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            title: Text(w.exerciseName,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${w.sets} sets × ${w.reps} reps'
                              '${w.weight > 0 ? ' @ ${w.weight}kg' : ''}',
                              style: const TextStyle(color: kTextMuted, fontSize: 12),
                            ),
                            trailing: Text(
                              DateFormat('HH:mm').format(w.timestamp),
                              style: const TextStyle(color: kTextMuted, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: state.todaysWorkouts.length,
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _dismissBg() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color:        kError.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: kError),
      );
}

// ─── Exercise Timer ───────────────────────────────────────────────────────────

class _ExerciseTimer extends StatelessWidget {
  const _ExerciseTimer({required this.state});
  final WorkoutState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          state.formattedElapsed,
          style: const TextStyle(
            color:      kTextPrimary,
            fontSize:   42,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timerBtn(
              icon:      Icons.refresh,
              color:     kTextMuted,
              onPressed: () => context.read<WorkoutBloc>().add(const WorkoutTimerReset()),
            ),
            const SizedBox(width: 16),
            _timerBtn(
              icon:      state.isTimerRunning ? Icons.pause : Icons.play_arrow,
              color:     kAccent,
              onPressed: () => context.read<WorkoutBloc>().add(
                state.isTimerRunning
                    ? const WorkoutTimerStopped()
                    : const WorkoutTimerStarted(),
              ),
              large: true,
            ),
            const SizedBox(width: 16),
            _timerBtn(
              icon:      Icons.stop,
              color:     kError,
              onPressed: () => context.read<WorkoutBloc>().add(const WorkoutTimerStopped()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timerBtn({
    required IconData icon,
    required Color    color,
    required VoidCallback onPressed,
    bool large = false,
  }) {
    final size = large ? 56.0 : 42.0;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width:       size,
        height:      size,
        decoration:  BoxDecoration(
          color:        color.withValues(alpha: 0.15),
          shape:        BoxShape.circle,
          border:       Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: color, size: large ? 28 : 20),
      ),
    );
  }
}

// ─── Rest Timer ───────────────────────────────────────────────────────────────

class _RestTimer extends StatelessWidget {
  const _RestTimer({required this.state});
  final WorkoutState state;

  @override
  Widget build(BuildContext context) {
    final secs = state.restRemainingSeconds;
    return Column(
      children: [
        const Text(
          'REST',
          style: TextStyle(
            color:      kIndigo,
            fontSize:   12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(
            color:      kIndigo,
            fontSize:   42,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value:           secs > 0 ? secs / 90 : 0,
            backgroundColor: kIndigo.withValues(alpha: 0.15),
            color:           kIndigo,
            minHeight:       6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Recover before your next set',
          style: TextStyle(color: kTextMuted, fontSize: 12),
        ),
      ],
    );
  }
}

// ─── Avatar State Chip ────────────────────────────────────────────────────────

class _AvatarStateChip extends StatelessWidget {
  const _AvatarStateChip({required this.avatarState});
  final AvatarState avatarState;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (avatarState) {
      AvatarState.idle       => ('IDLE',       kTextMuted),
      AvatarState.exercising => ('EXERCISING', kAccent),
      AvatarState.resting    => ('RESTING',    kIndigo),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      color,
          fontSize:   11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ─── Log Set Card ─────────────────────────────────────────────────────────────

class _LogSetCard extends StatelessWidget {
  const _LogSetCard({
    required this.exercise,
    required this.setsCtrl,
    required this.repsCtrl,
    required this.weightCtrl,
    required this.isBodyweight,
    required this.restSeconds,
    required this.onRestChanged,
    required this.onLog,
  });

  final ExerciseDefinition   exercise;
  final TextEditingController setsCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController weightCtrl;
  final bool                  isBodyweight;
  final int                   restSeconds;
  final ValueChanged<int>     onRestChanged;
  final VoidCallback          onLog;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(exercise.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color:      kTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize:   16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _numField('Sets', setsCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _numField('Reps', repsCtrl)),
                if (!isBodyweight) ...[
                  const SizedBox(width: 10),
                  Expanded(child: _numField('Weight (kg)', weightCtrl, decimal: true)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Rest:', style: TextStyle(color: kTextMuted, fontSize: 13)),
                const SizedBox(width: 8),
                for (final sec in [30, 60, 90, 120])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onRestChanged(sec),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: restSeconds == sec
                              ? kIndigo.withValues(alpha: 0.2)
                              : kCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: restSeconds == sec
                                ? kIndigo
                                : kIndigo.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${sec}s',
                          style: TextStyle(
                            color:    restSeconds == sec ? kIndigo : kTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            BlocBuilder<WorkoutBloc, WorkoutState>(
              builder: (ctx, state) => Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.isTimerRunning
                          ? null
                          : () => ctx.read<WorkoutBloc>()
                              .add(const WorkoutTimerStarted()),
                      icon:  const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start Set'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: kBackground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onLog,
                      icon:  const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Log Set'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kIndigo,
                        foregroundColor: kTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController ctrl,
      {bool decimal = false}) =>
      TextFormField(
        controller:    ctrl,
        style:         const TextStyle(color: kTextPrimary),
        keyboardType:  decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: decimal
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          isDense:   true,
        ),
      );
}