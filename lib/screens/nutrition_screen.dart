import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura_fit/blocs/nutrition/nutrition_bloc.dart';
import 'package:aura_fit/blocs/user/user_bloc.dart';
import 'package:aura_fit/widgets/macro_progress_bar.dart';
import 'package:aura_fit/widgets/nutrition_chart.dart';
import 'package:aura_fit/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _calCtrl    = TextEditingController();
  final _proCtrl    = TextEditingController();
  final _carbCtrl   = TextEditingController();
  final _fatCtrl    = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<NutritionBloc>().add(
      NutritionEntryAdded(
        foodName: _nameCtrl.text.trim(),
        calories: double.parse(_calCtrl.text.trim()),
        protein:  double.parse(_proCtrl.text.trim()),
        carbs:    double.parse(_carbCtrl.text.trim()),
        fats:     double.parse(_fatCtrl.text.trim()),
      ),
    );
    _nameCtrl.clear();
    _calCtrl.clear();
    _proCtrl.clear();
    _carbCtrl.clear();
    _fatCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NutritionBloc, NutritionState>(
      builder: (ctx, nutrState) {
        final userState = ctx.read<UserBloc>().state;
        return Scaffold(
          appBar: AppBar(title: const Text('Nutrition')),
          body: CustomScrollView(
            slivers: [
              // ── Daily Macro Progress ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TODAY\'S PROGRESS',
                                style: TextStyle(
                                  color:         kAccent,
                                  fontSize:      11,
                                  fontWeight:    FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              Text(
                                DateFormat('EEE, d MMM').format(DateTime.now()),
                                style: const TextStyle(
                                    color: kTextMuted, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MacroProgressBar(
                            label:   'Calories',
                            current: nutrState.totalCalories,
                            target:  userState.calorieTarget,
                            unit:    'kcal',
                            color:   kAccent,
                          ),
                          MacroProgressBar(
                            label:   'Protein',
                            current: nutrState.totalProtein,
                            target:  userState.proteinTarget,
                            unit:    'g',
                            color:   kIndigo,
                          ),
                          MacroProgressBar(
                            label:   'Carbs',
                            current: nutrState.totalCarbs,
                            target:  userState.carbsTarget,
                            unit:    'g',
                            color:   kWarning,
                          ),
                          MacroProgressBar(
                            label:   'Fats',
                            current: nutrState.totalFats,
                            target:  userState.fatsTarget,
                            unit:    'g',
                            color:   kError,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 7-Day History Chart ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '7-DAY CALORIE HISTORY',
                            style: TextStyle(
                              color:         kAccent,
                              fontSize:      11,
                              fontWeight:    FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          NutritionHistoryChart(
                            logs:           nutrState.historyLogs,
                            calorieTarget:  userState.calorieTarget,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Log Food Form ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LOG FOOD',
                              style: TextStyle(
                                color:         kAccent,
                                fontSize:      11,
                                fontWeight:    FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _nameCtrl,
                              style:      const TextStyle(color: kTextPrimary),
                              decoration: const InputDecoration(
                                  labelText: 'Food name'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                    child: _macroField('Calories', _calCtrl)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _macroField('Protein (g)', _proCtrl)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                    child: _macroField('Carbs (g)', _carbCtrl)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _macroField('Fats (g)', _fatCtrl)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _submit(ctx),
                                icon:  const Icon(Icons.add, size: 18),
                                label: const Text('Add Entry'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Today's entries ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    "TODAY'S ENTRIES",
                    style: TextStyle(
                      color:         kAccent.withValues(alpha: 0.8),
                      fontSize:      11,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
              if (nutrState.todaysLogs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No food logged yet today.\nAdd your first meal above!',
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
                        final log = nutrState.todaysLogs[i];
                        return Dismissible(
                          key:        Key('nutr_${log.id}'),
                          direction:  DismissDirection.endToStart,
                          background: _dismissBg(),
                          onDismissed: (_) => ctx.read<NutritionBloc>()
                              .add(NutritionEntryDeleted(log.id)),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log.foodName,
                                        style: const TextStyle(
                                          color:      kTextPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize:   14,
                                        ),
                                      ),
                                      Text(
                                        '${log.calories.toStringAsFixed(0)} kcal',
                                        style: const TextStyle(
                                          color:      kAccent,
                                          fontWeight: FontWeight.w700,
                                          fontSize:   14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _macroChip(
                                          'P ${log.protein.toStringAsFixed(0)}g',
                                          kIndigo),
                                      const SizedBox(width: 6),
                                      _macroChip(
                                          'C ${log.carbs.toStringAsFixed(0)}g',
                                          kWarning),
                                      const SizedBox(width: 6),
                                      _macroChip(
                                          'F ${log.fats.toStringAsFixed(0)}g',
                                          kError),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: nutrState.todaysLogs.length,
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _macroField(String label, TextEditingController ctrl) =>
      TextFormField(
        controller:    ctrl,
        style:         const TextStyle(color: kTextPrimary),
        keyboardType:  const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(labelText: label, isDense: true),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (double.tryParse(v.trim()) == null) return 'Invalid';
          return null;
        },
      );

  Widget _macroChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );

  Widget _dismissBg() => Container(
        alignment: Alignment.centerRight,
        padding:   const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color:        kError.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: kError),
      );
}