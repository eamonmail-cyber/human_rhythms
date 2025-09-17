import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date.dart';
import '../../data/models/entry.dart';
import '../../data/models/outcome.dart';
import '../../data/models/routine.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/entries_repo.dart';
import '../../data/repositories/outcomes_repo.dart';
import '../../data/repositories/routines_repo.dart';
import '../../features/auth/auth_controller.dart';

class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final now = DateTime.now();
    final days = List.generate(7, (i)=> ymd(now.subtract(Duration(days: i)))).reversed.toList();

    final entriesRepo  = ref.watch(repos.entriesRepoProvider);
    final outcomesRepo = ref.watch(outcomesRepoProvider);
    final routinesRepo = ref.watch(repos.routinesRepoProvider);

    return FutureBuilder(
      future: Future.wait([
        entriesRepo.byUserAndDates(userId, days),
        Future.wait(days.map((d)=> outcomesRepo.getForDate(userId, d))),
        routinesRepo.byUser(userId),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data as List;
        final entries = (data[0] as List<Entry>);
        final outcomes = (data[1] as List<Outcome?>);
        final routines = (data[2] as List<Routine>);

        final avgMood = _avg(outcomes.map((o)=> o?.mood));
        final avgEnergy = _avg(outcomes.map((o)=> o?.energy));
        final avgSleepQ = _avg(outcomes.map((o)=> o?.sleepQuality));

        // Simple insight: movement done vs energy
        final movementRoutineIds = routines.where((r)=> r.category == RoutineCategory.movement).map((r)=> r.id).toSet();
        final energyOnMovementDays = <int>[];
        final energyOnOtherDays = <int>[];

        // Map date -> any movement entry done
        final movementByDate = <String, bool>{};
        for (final e in entries) {
          if (movementRoutineIds.contains(e.routineId) && e.status == EntryStatus.done) {
            movementByDate[e.date] = true;
          } else {
            movementByDate.putIfAbsent(e.date, () => false);
          }
        }
        for (int i=0; i<days.length; i++) {
          final d = days[i];
          final energy = outcomes[i]?.energy;
          if (energy == null) continue;
          if (movementByDate[d] == true) {
            energyOnMovementDays.add(energy);
          } else {
            energyOnOtherDays.add(energy);
          }
        }

        final insightTexts = <String>[];
        if (avgMood != null) insightTexts.add("Average mood this week: ${avgMood.toStringAsFixed(1)}/10.");
        if (avgSleepQ != null) insightTexts.add("Average sleep quality: ${avgSleepQ.toStringAsFixed(1)}/10.");
        if (energyOnMovementDays.isNotEmpty && energyOnOtherDays.isNotEmpty) {
          final e1 = _avg(energyOnMovementDays.map((e)=> e));
          final e2 = _avg(energyOnOtherDays.map((e)=> e));
          if (e1 != null && e2 != null) {
            final diff = (e1 - e2);
            if (diff.abs() >= 0.5) {
              insightTexts.add("On days you moved, your energy averaged ${(e1).toStringAsFixed(1)} vs ${(e2).toStringAsFixed(1)} on other days.");
            }
          }
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Weekly Summary")),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (insightTexts.isEmpty)
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text("Keep logging — insights will appear here."),
                )
              else
                for (final t in insightTexts)
                  ListTile(leading: const Icon(Icons.lightbulb_outline), title: Text(t)),
            ],
          ),
        );
      },
    );
  }

  double? _avg(Iterable<int?> values) {
    final v = values.where((e)=> e != null).cast<int>().toList();
    if (v.isEmpty) return null;
    return v.reduce((a,b)=> a+b) / v.length;
  }
}
