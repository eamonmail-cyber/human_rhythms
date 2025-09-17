import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/enums.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/entries_repo.dart';
import '../../data/repositories/outcomes_repo.dart';
import '../../data/repositories/routines_repo.dart';

class RoutineEditor extends ConsumerStatefulWidget {
  final Routine routine;
  final bool isNew;
  const RoutineEditor({super.key, required this.routine, this.isNew = false});

  @override
  ConsumerState<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends ConsumerState<RoutineEditor> {
  late TextEditingController titleCtrl;
  RoutineCategory category = RoutineCategory.mind;
  String frequency = "daily";
  String? targetTime;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.routine.title);
    category = widget.routine.category;
    frequency = widget.routine.frequency;
    targetTime = widget.routine.targetTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Routine")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
          const SizedBox(height: 8),
          DropdownButtonFormField<RoutineCategory>(
            value: category,
            items: RoutineCategory.values.map((c)=> DropdownMenuItem(value: c, child: Text(c.name))).toList(),
            onChanged: (v)=> setState(()=> category = v ?? category),
            decoration: const InputDecoration(labelText: "Category"),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: frequency,
            items: const [
              DropdownMenuItem(value: "daily", child: Text("Daily")),
              DropdownMenuItem(value: "weekly", child: Text("Weekly")),
              DropdownMenuItem(value: "monthly", child: Text("Monthly")),
            ],
            onChanged: (v)=> setState(()=> frequency = v ?? frequency),
            decoration: const InputDecoration(labelText: "Frequency"),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: targetTime ?? "",
            decoration: const InputDecoration(labelText: "Target time (HH:MM) optional"),
            onChanged: (v)=> setState(()=> targetTime = v.isEmpty ? null : v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () async {
            final repo = ref.read(repos.routinesRepoProvider);
            final updated = Routine(
              id: widget.routine.id,
              userId: widget.routine.userId,
              title: titleCtrl.text.trim().isEmpty ? "Untitled" : titleCtrl.text.trim(),
              category: category,
              targetTime: targetTime,
              frequency: frequency,
              daysOfWeek: null,
              captureIntensity: true,
              captureDuration: true,
              captureNote: true,
              active: true,
              version: widget.routine.version + 1,
              createdAt: widget.routine.createdAt,
              updatedAt: DateTime.now(),
            );
            await repo.save(updated);
            if (mounted) Navigator.pop(context);
          }, child: const Text("Save")),
        ],
      ),
    );
  }
}
