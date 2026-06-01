import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura_fit/blocs/user/user_bloc.dart';
import 'package:aura_fit/services/avatar_service.dart';
import 'package:aura_fit/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _bodyFatCtrl;

  String _gender  = 'male';
  bool   _editing = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<UserBloc>().state;
    _nameCtrl    = TextEditingController(text: s.user?.name    ?? '');
    _ageCtrl     = TextEditingController(text: s.user?.age.toString()     ?? '');
    _heightCtrl  = TextEditingController(text: s.user?.height.toString()  ?? '');
    _weightCtrl  = TextEditingController(text: s.user?.weight.toString()  ?? '');
    _bodyFatCtrl = TextEditingController(text: s.user?.bodyFat.toString() ?? '');
    _gender      = s.user?.gender ?? 'male';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final s = context.read<UserBloc>().state;
    context.read<UserBloc>().add(
      UserUpdated(
        id:      s.user?.id,
        name:    _nameCtrl.text.trim(),
        age:     int.parse(_ageCtrl.text.trim()),
        gender:  _gender,
        height:  double.parse(_heightCtrl.text.trim()),
        weight:  double.parse(_weightCtrl.text.trim()),
        bodyFat: double.parse(_bodyFatCtrl.text.trim()),
      ),
    );
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:          Text('Profile saved!'),
        backgroundColor: kAccent,
        duration:        Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (ctx, state) {
        if (!_editing && state.user != null) {
          _nameCtrl.text    = state.user!.name;
          _ageCtrl.text     = state.user!.age.toString();
          _heightCtrl.text  = state.user!.height.toString();
          _weightCtrl.text  = state.user!.weight.toString();
          _bodyFatCtrl.text = state.user!.bodyFat.toString();
          _gender           = state.user!.gender;
        }
      },
      builder: (ctx, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Profile & Biometrics'),
          actions: [
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
              onPressed: () => setState(() => _editing = !_editing),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BiometricsCard(
                  nameCtrl:    _nameCtrl,
                  ageCtrl:     _ageCtrl,
                  heightCtrl:  _heightCtrl,
                  weightCtrl:  _weightCtrl,
                  bodyFatCtrl: _bodyFatCtrl,
                  gender:      _gender,
                  editing:     _editing,
                  onGenderChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 20),
                if (_editing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon:  const Icon(Icons.save_outlined),
                      label: const Text('Save Profile'),
                    ),
                  ),
                const SizedBox(height: 24),
                _MacroTargetsCard(state: state),
                const SizedBox(height: 20),
                ValueListenableBuilder<String?>(
                  valueListenable:
                      context.read<AvatarService>().avatarGlbUrl,
                  builder: (_, url, __) => _AvatarCard(glbUrl: url),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Biometrics Card ──────────────────────────────────────────────────────────

class _BiometricsCard extends StatelessWidget {
  const _BiometricsCard({
    required this.nameCtrl,
    required this.ageCtrl,
    required this.heightCtrl,
    required this.weightCtrl,
    required this.bodyFatCtrl,
    required this.gender,
    required this.editing,
    required this.onGenderChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController ageCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController bodyFatCtrl;
  final String                gender;
  final bool                  editing;
  final ValueChanged<String>  onGenderChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Personal Info'),
            const SizedBox(height: 16),
            _field('Name', nameCtrl, editing, hint: 'Your name'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field('Age', ageCtrl, editing, hint: 'Years', numeric: true)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gender',
                          style: TextStyle(color: kTextMuted, fontSize: 12)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color:        kCard,
                          borderRadius: BorderRadius.circular(12),
                          border:       Border.all(
                            color: kIndigo.withValues(alpha: 0.4),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:         gender,
                            isExpanded:    true,
                            onChanged:     editing ? (v) => onGenderChanged(v!) : null,
                            dropdownColor: kCard,
                            padding:       const EdgeInsets.symmetric(horizontal: 12),
                            items: const [
                              DropdownMenuItem(value: 'male',   child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionTitle('Body Metrics'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field('Height', heightCtrl, editing, hint: 'cm',  decimal: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Weight', weightCtrl, editing, hint: 'kg',  decimal: true)),
              ],
            ),
            const SizedBox(height: 12),
            _field('Body Fat', bodyFatCtrl, editing, hint: '%', decimal: true),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color:      kAccent,
          fontSize:   12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      );

  Widget _field(
    String label,
    TextEditingController ctrl,
    bool enabled, {
    String hint    = '',
    bool numeric   = false,
    bool decimal   = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: kTextMuted, fontSize: 12)),
          const SizedBox(height: 6),
          TextFormField(
            controller:    ctrl,
            enabled:       enabled,
            style:         const TextStyle(color: kTextPrimary),
            keyboardType:  decimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : numeric
                    ? TextInputType.number
                    : TextInputType.text,
            inputFormatters: decimal
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : numeric
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
            decoration: InputDecoration(hintText: hint),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if ((numeric || decimal) && double.tryParse(v.trim()) == null) {
                return 'Invalid number';
              }
              return null;
            },
          ),
        ],
      );
}

// ─── Macro Targets Card ───────────────────────────────────────────────────────

class _MacroTargetsCard extends StatelessWidget {
  const _MacroTargetsCard({required this.state});

  final UserState state;

  @override
  Widget build(BuildContext context) {
    if (state.user == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Fill in your biometrics above to see your macro targets.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DAILY TARGETS',
                  style: TextStyle(
                    color:      kAccent,
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        kAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'BMR ${state.bmr.toStringAsFixed(0)} kcal',
                    style: const TextStyle(color: kAccent, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _macroRow('Calories',  state.calorieTarget, 'kcal', kAccent),
            _macroRow('Protein',   state.proteinTarget, 'g',    kIndigo),
            _macroRow('Carbs',     state.carbsTarget,   'g',    kWarning),
            _macroRow('Fats',      state.fatsTarget,    'g',    kError),
          ],
        ),
      ),
    );
  }

  Widget _macroRow(String name, double value, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width:        8,
            height:       8,
            margin:       const EdgeInsets.only(right: 10),
            decoration:   BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Text(name,
              style: const TextStyle(color: kTextPrimary, fontSize: 14)),
          const Spacer(),
          Text(
            '${value.toStringAsFixed(0)} $unit',
            style: TextStyle(
              color:      color,
              fontSize:   15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar Card ──────────────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.glbUrl});

  final String? glbUrl;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = glbUrl != null && glbUrl!.isNotEmpty;
    final avatarId  = hasAvatar
        ? glbUrl!.split('/').last.split('?').first.replaceAll('.glb', '')
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '3D AVATAR',
                  style: TextStyle(
                    color:         kAccent,
                    fontSize:      12,
                    fontWeight:    FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasAvatar
                        ? kAccent.withValues(alpha: 0.15)
                        : kTextMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasAvatar ? 'Configured' : 'Not set',
                    style: TextStyle(
                      color:    hasAvatar ? kAccent : kTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Status ───────────────────────────────────────────────────────
            if (hasAvatar) ...[
              Row(
                children: [
                  Container(
                    width:  44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:  kIndigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: kIndigo.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(
                      Icons.view_in_ar_rounded,
                      color: kIndigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: $avatarId',
                          style: const TextStyle(
                            color:      kTextPrimary,
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ready Player Me • .glb model',
                          style: TextStyle(color: kTextMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ] else ...[
              const Text(
                'No avatar configured yet.\nCreate your personalised 3D character — '
                'it will drive the GymAvatar animation states.',
                style: TextStyle(color: kTextMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
            ],

            // ── Navigation hint ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.touch_app_outlined,
                    size: 14, color: kTextMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasAvatar
                        ? 'Modify your avatar in the Avatar tab.'
                        : 'Open the Avatar tab below to create your avatar.',
                    style: const TextStyle(
                      color:     kTextMuted,
                      fontSize:  12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}