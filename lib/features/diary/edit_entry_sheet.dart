import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/enums.dart';
import '../../data/models/entry.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/repo_providers.dart' as repos;

class EditEntrySheet extends ConsumerStatefulWidget {
  final Entry? initial;
  final Routine routine;
  final String dateStr;
  final String userId;
  const EditEntrySheet({super.key, this.initial, required this.routine, required this.dateStr, required this.userId});
  @override
  ConsumerState<EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends ConsumerState<EditEntrySheet> {
  int _intensity = 5;
  int _duration = 20;
  EntryStatus _status = EntryStatus.done;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _intensity = i.intensity ?? 5;
      _duration  = i.durationMin ?? 20;
      _status    = i.status;
      _noteCtrl.text = i.note ?? '';
    }
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(repos.entriesRepoProvider);
    final id = widget.initial?.id ?? const Uuid().v4();
    final e = Entry(
      id: id,
      userId: widget.userId,
      routineId: widget.routine.id,
      date: widget.dateStr,
      timeBucket: _bucketFor(widget.routine.targetTime),
      status: _status,
      durationMin: _duration,
      intensity: _intensity,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      tags: const [],
      routineVersionAtLog: widget.routine.version,
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
    );
    await repo.upsert(e);
    if (mounted) Navigator.pop(context, e);
  }

  TimeBucket _bucketFor(String? hhmm) {
    if (hhmm == null) return TimeBucket.custom;
    try {
      final h = int.parse(hhmm.split(':')[0]);
      if (h < 12) return TimeBucket.morning;
      if (h < 17) return TimeBucket.midday;
      return TimeBucket.evening;
    } catch (_) { return TimeBucket.custom; }
  }

  Color get _catColor => switch(widget.routine.category) {
    RoutineCategory.sleep      => kCatSleep,
    RoutineCategory.movement   => kCatMovement,
    RoutineCategory.food       => kCatFood,
    RoutineCategory.mind       => kCatMind,
    RoutineCategory.social     => kCatSocial,
    RoutineCategory.work       => kCatWork,
    RoutineCategory.health     => kCatHealth,
    RoutineCategory.reflection => kCatReflection,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 8,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: kDivider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          // Header
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _catColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(_catIcon, color: _catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.routine.title,
                style: Theme.of(context).textTheme.titleLarge)),
            IconButton(icon: const Icon(Icons.close_rounded), color: kTextMid,
                onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 20),
          // Status chips
          Text('HOW DID IT GO?', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Row(children: [
            for (final s in [EntryStatus.done, EntryStatus.partial, EntryStatus.skipped])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _StatusChip(
                  label: switch(s) { EntryStatus.done => '✓  Done', EntryStatus.partial => '◑  Partial', _ => '–  Skipped' },
                  selected: _status == s,
                  color: switch(s) { EntryStatus.done => kPrimary, EntryStatus.partial => kCatFood, _ => kTextLight },
                  onTap: () => setState(() => _status = s),
                ),
              ),
          ]),
          if (_status != EntryStatus.skipped) ...[
            const SizedBox(height: 20),
            Text('INTENSITY  ·  ${_intensity}/10', style: Theme.of(context).textTheme.titleSmall),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(activeTrackColor: _catColor, thumbColor: _catColor, inactiveTrackColor: kDivider),
              child: Slider(value: _intensity.toDouble(), min: 0, max: 10, divisions: 10,
                  onChanged: (v) => setState(() => _intensity = v.toInt())),
            ),
            Text('DURATION  ·  ${_duration} min', style: Theme.of(context).textTheme.titleSmall),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(activeTrackColor: _catColor, thumbColor: _catColor, inactiveTrackColor: kDivider),
              child: Slider(value: _duration.toDouble(), min: 0, max: 120, divisions: 24,
                  onChanged: (v) => setState(() => _duration = v.toInt())),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLength: 300,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'How did it feel? Any observations...',
              counterStyle: TextStyle(color: kTextLight),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Save Entry'),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _catIcon => switch(widget.routine.category) {
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

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : kDivider, width: selected ? 2 : 1),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? color : kTextMid)),
      ),
    );
  }
}
