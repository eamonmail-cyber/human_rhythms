import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../data/services/firebase_service.dart';
import '../../services/lookback_service.dart';

class LookbackView extends StatefulWidget {
  final String userId;
  const LookbackView({super.key, required this.userId});

  @override
  State<LookbackView> createState() => _LookbackViewState();
}

class _LookbackViewState extends State<LookbackView> {
  late Future<_LookbackData> _future;

  // Compare state
  int? _compareA;
  int? _compareB;
  bool _showCompare = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = _fetch();
  }

  Future<_LookbackData> _fetch() async {
    final summaries = await LookbackService.generate(widget.userId);
    final snap = await Fb.col('milestones')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('date', descending: true)
        .get();
    final milestones =
        snap.docs.map((d) => MilestoneItem.fromMap(d.id, d.data())).toList();
    return _LookbackData(summaries: summaries, milestones: milestones);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LookbackData>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Could not load journey data.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600])),
              ],
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        final data = snap.data!;
        return _buildContent(context, data);
      },
    );
  }

  Widget _buildContent(BuildContext context, _LookbackData data) {
    final summaries = data.summaries;
    final milestones = data.milestones;
    final bestIdx = _bestMonthIndex(summaries);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Top nudge
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withOpacity(0.15)),
                  ),
                  child: Text(
                    'You cannot always feel the change. But you can see it here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: kTextMid,
                        ),
                  ),
                ),
              ),
            ),
            // Compare result
            if (_showCompare &&
                _compareA != null &&
                _compareB != null &&
                _compareA! < summaries.length &&
                _compareB! < summaries.length)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _CompareCard(
                    a: summaries[_compareA!],
                    b: summaries[_compareB!],
                    onClose: () => setState(() => _showCompare = false),
                  ),
                ),
              ),
            // Month cards
            for (var i = 0; i < summaries.length; i++) ...[
              // Milestone markers for this month
              for (final m in milestones.where((ms) {
                if (ms.date.length < 7) return false;
                final mYM = ms.date.substring(0, 7);
                final sYM =
                    '${summaries[i].month.year}-${summaries[i].month.month.toString().padLeft(2, '0')}';
                return mYM == sYM;
              }))
                SliverToBoxAdapter(
                  child: _MilestoneMarker(milestone: m),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _MonthCard(
                    summary: summaries[i],
                    isBest: i == bestIdx,
                    onViewDiary: () => context.go('/'),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        // FABs bottom-right
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'compareFab',
                onPressed: () => _showCompareSheet(context, data.summaries),
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.compare_arrows_rounded),
                label: const Text('Compare two months'),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'milestoneFab',
                onPressed: () => _showAddMilestone(context),
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                child: const Icon(Icons.flag_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _bestMonthIndex(List<MonthSummary> summaries) {
    if (summaries.isEmpty) return -1;
    var best = 0;
    for (var i = 1; i < summaries.length; i++) {
      if (summaries[i].completionRate > summaries[best].completionRate) {
        best = i;
      }
    }
    return best;
  }

  void _showCompareSheet(BuildContext context, List<MonthSummary> summaries) {
    var idxA = 0;
    var idxB = summaries.length > 1 ? 1 : 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: kDivider,
                        borderRadius: BorderRadius.circular(2))),
              ),
              Text('Compare Two Months',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: idxA,
                      decoration: const InputDecoration(labelText: 'Month A'),
                      items: [
                        for (var i = 0; i < summaries.length; i++)
                          DropdownMenuItem(
                              value: i, child: Text(summaries[i].monthLabel))
                      ],
                      onChanged: (v) => setModal(() => idxA = v ?? 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: idxB,
                      decoration: const InputDecoration(labelText: 'Month B'),
                      items: [
                        for (var i = 0; i < summaries.length; i++)
                          DropdownMenuItem(
                              value: i, child: Text(summaries[i].monthLabel))
                      ],
                      onChanged: (v) =>
                          setModal(() => idxB = v ?? (summaries.length > 1 ? 1 : 0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _compareA = idxA;
                      _compareB = idxB;
                      _showCompare = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary, foregroundColor: Colors.white),
                  child: const Text('Compare'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMilestone(BuildContext context) {
    final textCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: kDivider,
                          borderRadius: BorderRadius.circular(2))),
                ),
                Text('Add Milestone',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                            colorScheme:
                                const ColorScheme.light(primary: kPrimary)),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setModal(() => selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  style: const TextStyle(color: kTextDark),
                  decoration: const InputDecoration(
                    hintText: 'Describe this milestone...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (textCtrl.text.trim().isEmpty) return;
                      final ds =
                          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                      final ms = MilestoneItem(
                        id: const Uuid().v4(),
                        userId: widget.userId,
                        date: ds,
                        note: textCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      await Fb.col('milestones').doc(ms.id).set(ms.toMap());
                      if (mounted) {
                        Navigator.pop(context);
                        setState(_loadData);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary, foregroundColor: Colors.white),
                    child: const Text('Save Milestone'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Month Card ────────────────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  final MonthSummary summary;
  final bool isBest;
  final VoidCallback onViewDiary;

  const _MonthCard({
    required this.summary,
    required this.isBest,
    required this.onViewDiary,
  });

  @override
  Widget build(BuildContext context) {
    final pct = summary.completionRate;
    final barColor = pct > 0.75
        ? const Color(0xFF4CAF50)
        : pct > 0.5
            ? const Color(0xFFFFC107)
            : kAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.monthLabel,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (isBest)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Best month ⭐',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 6,
                        backgroundColor: kDivider,
                        color: barColor,
                        strokeCap: StrokeCap.round,
                      ),
                      Text('${(pct * 100).round()}%',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: barColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Completion bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                color: barColor,
                backgroundColor: kDivider,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                if (summary.avgMood != null) ...[
                  const Text('😊', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(summary.avgMood!.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: kTextDark)),
                  const SizedBox(width: 16),
                ],
                if (summary.avgEnergy != null) ...[
                  const Text('⚡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(summary.avgEnergy!.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: kTextDark)),
                ],
                const Spacer(),
                if (summary.routinesAdded > 0)
                  _Tag('+${summary.routinesAdded}', Colors.green),
                if (summary.routinesRemoved > 0) ...[
                  const SizedBox(width: 4),
                  _Tag('-${summary.routinesRemoved}', kAccent),
                ],
              ],
            ),
            if (summary.bestDay != null) ...[
              const SizedBox(height: 8),
              Text(
                'Best day: ${_formatDate(summary.bestDay!)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: kTextMid, fontSize: 12),
              ),
            ],
            if (isBest) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'This was your best month. What were you doing differently?',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic, color: kTextMid),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onViewDiary,
                icon: const Icon(Icons.today_rounded, size: 16, color: kPrimary),
                label: const Text('View diary',
                    style: TextStyle(color: kPrimary, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String ds) {
    try {
      final d = DateTime.parse(ds);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return ds;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Milestone Marker ──────────────────────────────────────────────────────────

class _MilestoneMarker extends StatelessWidget {
  final MilestoneItem milestone;
  const _MilestoneMarker({required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: kPrimary, width: 4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_rounded, color: kPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(milestone.note,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13)),
                  Text(milestone.date,
                      style: const TextStyle(
                          fontSize: 11, color: kTextMid)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compare Card ──────────────────────────────────────────────────────────────

class _CompareCard extends StatelessWidget {
  final MonthSummary a;
  final MonthSummary b;
  final VoidCallback onClose;
  const _CompareCard({required this.a, required this.b, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kPrimary.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Comparison',
                        style: Theme.of(context).textTheme.titleMedium)),
                IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: kTextLight,
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MonthCol(a)),
                Container(width: 1, height: 80, color: kDivider),
                Expanded(child: _MonthCol(b)),
              ],
            ),
            const SizedBox(height: 12),
            if (a.avgMood != null && b.avgMood != null)
              _DiffRow('Mood', a.avgMood!, b.avgMood!),
            if (a.avgEnergy != null && b.avgEnergy != null)
              _DiffRow('Energy', a.avgEnergy!, b.avgEnergy!),
            _DiffRow(
                'Completion', a.completionRate * 10, b.completionRate * 10),
          ],
        ),
      ),
    );
  }
}

class _MonthCol extends StatelessWidget {
  final MonthSummary s;
  const _MonthCol(this.s);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(s.monthLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('${(s.completionRate * 100).round()}%',
              style: const TextStyle(
                  color: kPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final String label;
  final double valA;
  final double valB;
  const _DiffRow(this.label, this.valA, this.valB);

  @override
  Widget build(BuildContext context) {
    final diff = valB - valA;
    final isUp = diff > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: kTextMid, fontSize: 12))),
          Text(valA.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const Text(' → ',
              style: TextStyle(color: kTextLight, fontSize: 12)),
          Text(valB.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(width: 6),
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isUp ? Colors.green : kAccent,
            size: 14,
          ),
          Text(
            '${isUp ? '+' : ''}${diff.toStringAsFixed(1)}',
            style: TextStyle(
                fontSize: 12,
                color: isUp ? Colors.green : kAccent,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Internal data holder ──────────────────────────────────────────────────────

class _LookbackData {
  final List<MonthSummary> summaries;
  final List<MilestoneItem> milestones;
  const _LookbackData({required this.summaries, required this.milestones});
}
