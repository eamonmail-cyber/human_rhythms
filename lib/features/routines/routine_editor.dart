import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/models/enums.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/repo_providers.dart' as repos;

class RoutineEditor extends ConsumerStatefulWidget {
  final Routine routine;
  final bool isNew;
  const RoutineEditor({super.key, required this.routine, this.isNew = false});
  @override
  ConsumerState<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends ConsumerState<RoutineEditor> {
  late TextEditingController _titleCtrl;
  late RoutineCategory _category;
  late String _frequency;
  TimeOfDay? _targetTime;
  bool _isPublic = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.routine.title);
    _category  = widget.routine.category;
    _frequency = widget.routine.frequency;
    if (widget.routine.targetTime != null) {
      final parts = widget.routine.targetTime!.split(':');
      _targetTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your routine a name'), backgroundColor: kAccent),
      );
      return;
    }
    setState(() => _saving = true);
    final updated = Routine(
      id: widget.routine.id,
      userId: widget.routine.userId,
      title: _titleCtrl.text.trim(),
      category: _category,
      targetTime: _targetTime != null
          ? '${_targetTime!.hour.toString().padLeft(2, '0')}:${_targetTime!.minute.toString().padLeft(2, '0')}'
          : null,
      frequency: _frequency,
      daysOfWeek: null,
      captureIntensity: true, captureDuration: true, captureNote: true,
      active: true,
      version: widget.routine.version + 1,
      createdAt: widget.routine.createdAt,
      updatedAt: DateTime.now(),
    );
    await ref.read(repos.routinesRepoProvider).save(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text(widget.isNew ? 'New Routine' : 'Edit Routine'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: kPrimary))
                : const Text('Save', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            title: 'Routine Name',
            child: TextField(
              controller: _titleCtrl,
              autofocus: widget.isNew,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'e.g. Morning Walk, Meditation...'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Category',
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
              children: RoutineCategory.values.map((c) {
                final selected = _category == c;
                final color = _colorFor(c);
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.15) : kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? color : kDivider, width: selected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_iconFor(c), color: selected ? color : kTextLight, size: 24),
                        const SizedBox(height: 4),
                        Text(c.name, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: selected ? color : kTextMid)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Frequency',
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily',   label: Text('Daily')),
                ButtonSegment(value: 'weekly',  label: Text('Weekly')),
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ],
              selected: {_frequency},
              onSelectionChanged: (s) => setState(() => _frequency = s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) return kPrimary;
                  return kCard;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return kTextMid;
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Target Time (optional)',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.schedule_rounded, color: kPrimary),
              ),
              title: Text(
                _targetTime != null ? _targetTime!.format(context) : 'Any time',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Sets which part of day this appears'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_targetTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: kTextLight),
                      onPressed: () => setState(() => _targetTime = null),
                    ),
                  const Icon(Icons.chevron_right_rounded, color: kTextLight),
                ],
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _targetTime ?? TimeOfDay.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _targetTime = picked);
              },
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Visibility',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share publicly', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_isPublic
                  ? 'Others can browse and follow your routine'
                  : 'Only you can see this routine'),
              value: _isPublic,
              activeColor: kPrimary,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(widget.isNew ? 'Create Routine' : 'Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(RoutineCategory c) => switch(c) {
    RoutineCategory.sleep      => kCatSleep,
    RoutineCategory.movement   => kCatMovement,
    RoutineCategory.food       => kCatFood,
    RoutineCategory.mind       => kCatMind,
    RoutineCategory.social     => kCatSocial,
    RoutineCategory.work       => kCatWork,
    RoutineCategory.health     => kCatHealth,
    RoutineCategory.reflection => kCatReflection,
  };

  IconData _iconFor(RoutineCategory c) => switch(c) {
    RoutineCategory.sleep      => Icons.bedtime_outlined,
    RoutineCategory.movement   => Icons.directions_run_rounded,
    RoutineCategory.food       => Icons.restaurant_outlined,
    RoutineCategory.mind       => Icons.self_improvement_outlined,
    RoutineCategory.social     => Icons.people_outline_rounded,
    RoutineCategory.work       => Icons.work_outline_rounded,
    RoutineCategory.health     => Icons.favorite_outline_rounded,
    RoutineCategory.reflection => Icons.auto_stories_outlined,
  };
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
