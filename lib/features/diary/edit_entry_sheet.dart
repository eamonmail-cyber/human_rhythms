import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/enums.dart';
import '../../data/models/entry.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/entries_repo.dart';

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
  int intensity = 5;
  int duration = 20;
  EntryStatus status = EntryStatus.done;
  final noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      intensity = i.intensity ?? 5;
      duration = i.durationMin ?? 20;
      status = i.status;
      noteCtrl.text = i.note ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left:16, right:16, top:12, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(widget.routine.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Done'), selected: status==EntryStatus.done, onSelected: (_) => setState(()=> status=EntryStatus.done)),
            ChoiceChip(label: const Text('Skipped'), selected: status==EntryStatus.skipped, onSelected: (_) => setState(()=> status=EntryStatus.skipped)),
            ChoiceChip(label: const Text('Partial'), selected: status==EntryStatus.partial, onSelected: (_) => setState(()=> status=EntryStatus.partial)),
          ]),
          const SizedBox(height: 12),
          Text("Intensity ($intensity)"),
          Slider(value: intensity.toDouble(), min: 0, max: 10, divisions: 10, onChanged: (v)=> setState(()=> intensity=v.toInt())),
          const SizedBox(height: 4),
          Text("Duration min ($duration)"),
          Slider(value: duration.toDouble(), min: 0, max: 120, divisions: 24, onChanged: (v)=> setState(()=> duration=v.toInt())),
          const SizedBox(height: 8),
          TextField(controller: noteCtrl, maxLength: 240, decoration: const InputDecoration(labelText: "Note / tags")),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () async {
            final repo = ref.read(repos.entriesRepoProvider);
            final id = widget.initial?.id ?? const Uuid().v4();
            final e = Entry(
              id: id,
              userId: widget.userId,
              routineId: widget.routine.id,
              date: widget.dateStr,
              timeBucket: _bucketFor(widget.routine.targetTime),
              status: status,
              durationMin: duration,
              intensity: intensity,
              note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
              tags: const [],
              routineVersionAtLog: widget.routine.version,
              createdAt: DateTime.now(),
            );
            await repo.upsert(e);
            if (mounted) Navigator.pop(context, e);
          }, child: const Text("Save")),
        ]),
      ),
    );
  }

  TimeBucket _bucketFor(String? hhmm) {
    if (hhmm == null) return TimeBucket.custom;
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      if (h < 12) return TimeBucket.morning;
      if (h < 17) return TimeBucket.midday;
      return TimeBucket.evening;
    } catch (_) {
      return TimeBucket.custom;
    }
  }
}
