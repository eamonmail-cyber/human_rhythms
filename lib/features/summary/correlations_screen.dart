import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/correlation_service.dart';

class CorrelationsView extends StatefulWidget {
  final String userId;
  const CorrelationsView({super.key, required this.userId});

  @override
  State<CorrelationsView> createState() => _CorrelationsViewState();
}

class _CorrelationsViewState extends State<CorrelationsView> {
  late Future<List<CorrelationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = CorrelationService.generate(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CorrelationItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('Could not load patterns.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600])),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        final items = snap.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // Header
            Text(
              'Based on your data, here is what seems to be working.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: kTextDark),
            ),
            const SizedBox(height: 12),
            // Mindset nudge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimary.withOpacity(0.15)),
              ),
              child: Text(
                'Change one thing. Track one thing. See what happens.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: kTextMid,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            // Items or empty state
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kDivider),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.bar_chart_rounded,
                        color: kTextLight, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Correlations appear after 2 weeks of consistent logging.\n'
                      'Keep tracking — the patterns will emerge.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else
              for (final item in items) ...[
                _CorrelationCard(item: item),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

// ── Correlation Card ──────────────────────────────────────────────────────────

class _CorrelationCard extends StatelessWidget {
  final CorrelationItem item;
  const _CorrelationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final maxVal = [item.avgWith, item.avgWithout, 10.0].reduce(
        (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routine + outcome header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.routineTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: kTextDark)),
                      const SizedBox(height: 2),
                      Text(
                          '${item.routineCategory} · ${item.outcomeName}',
                          style: const TextStyle(
                              fontSize: 12, color: kTextMid)),
                    ],
                  ),
                ),
                Icon(
                  item.isPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: item.isPositive ? Colors.green : kAccent,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Bar comparison
            _BarRow(
              label: 'Done',
              value: item.avgWith,
              maxValue: maxVal,
              color: item.isPositive ? kPrimary : kAccent,
            ),
            const SizedBox(height: 8),
            _BarRow(
              label: 'Skipped',
              value: item.avgWithout,
              maxValue: maxVal,
              color: kTextLight,
              muted: true,
            ),
            const SizedBox(height: 12),
            // Plain English
            Text(
              item.isPositive
                  ? 'When you complete ${item.routineTitle}, your ${item.outcomeName} tends to be ${item.difference.toStringAsFixed(1)} points higher.'
                  : 'When you skip ${item.routineTitle}, your ${item.outcomeName} tends to be ${item.difference.abs().toStringAsFixed(1)} points lower.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: kTextMid),
            ),
            const SizedBox(height: 10),
            // Confidence + data points
            Row(
              children: [
                Row(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < item.confidenceLevel
                              ? kPrimary
                              : kDivider,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Based on ${item.dataPoints} days of data',
                  style: const TextStyle(fontSize: 11, color: kTextLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final bool muted;
  const _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final frac = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: kTextMid)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              color: muted ? kTextLight : color,
              backgroundColor: kDivider,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: kTextDark),
          ),
        ),
      ],
    );
  }
}
