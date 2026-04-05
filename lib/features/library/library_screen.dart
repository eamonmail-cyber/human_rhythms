import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/library_routine.dart';
import '../../providers/global.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? _category;
  bool _expertsOnly = false;
  List<LibraryRoutine> _routines = [];
  bool _loading = true;
  String? _adoptingId;
  String? _error;

  static const _cats = [
    'sleep', 'movement', 'food', 'mind', 'social', 'work', 'health', 'reflection',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ref.read(libraryRepoProvider).getRoutines(
        category: _category,
        expertsOnly: _expertsOnly,
      );
      if (mounted) setState(() { _routines = items; _loading = false; });
    } catch (e, st) {
      debugPrint('[Library] Firestore load error: $e\n$st');
      if (mounted) setState(() { _routines = []; _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _adopt(LibraryRoutine r) async {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    setState(() => _adoptingId = r.id);
    try {
      await ref.read(libraryRepoProvider).adoptRoutine(
        libraryRoutineId: r.id,
        userId: uid,
        routine: r,
      );
      if (!mounted) return;
      setState(() => _adoptingId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${r.title} added to your routines'),
        backgroundColor: kPrimary,
      ));
      _load();
    } catch (e, st) {
      debugPrint('[Library] Firestore adopt error: $e\n$st');
      if (!mounted) return;
      setState(() => _adoptingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add routine. Please try again.'),
          backgroundColor: kAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Library',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _chip('All', _category == null,
                    () => setState(() { _category = null; _load(); })),
                ..._cats.map((c) => _chip(
                      _cap(c),
                      _category == c,
                      () => setState(() { _category = c; _load(); }),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Experts only',
                    style: TextStyle(color: kTextMid, fontSize: 13)),
                const Spacer(),
                Switch(
                  value: _expertsOnly,
                  activeColor: kPrimary,
                  onChanged: (v) => setState(() { _expertsOnly = v; _load(); }),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kDivider),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : _error != null
                    ? RefreshIndicator(
                        color: kPrimary,
                        onRefresh: _load,
                        child: ListView(
                          children: [
                            SizedBox(
                              height: 300,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.cloud_off_outlined,
                                          size: 48, color: kTextLight),
                                      const SizedBox(height: 12),
                                      const Text('Couldn\'t load the library',
                                          style: TextStyle(
                                              color: kTextDark,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 6),
                                      const Text('Pull down to try again.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: kTextMid, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _routines.isEmpty
                    ? const Center(
                        child: Text('No routines found',
                            style: TextStyle(color: kTextLight)))
                    : RefreshIndicator(
                        color: kPrimary,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _routines.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _RoutineCard(
                            routine: _routines[i],
                            adopting: _adoptingId == _routines[i].id,
                            onAdopt: () => _adopt(_routines[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          selectedColor: kPrimary.withOpacity(0.15),
          checkmarkColor: kPrimary,
          onSelected: (_) => onTap(),
        ),
      );

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _RoutineCard extends StatelessWidget {
  final LibraryRoutine routine;
  final bool adopting;
  final VoidCallback onAdopt;

  const _RoutineCard({
    required this.routine,
    required this.adopting,
    required this.onAdopt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCard,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    routine.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kTextDark),
                  ),
                ),
                if (routine.isVerifiedExpert)
                  Tooltip(
                    message: routine.expertCredential ?? 'Verified Expert',
                    child: const Icon(Icons.verified_rounded,
                        color: kPrimary, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(routine.authorName,
                style: const TextStyle(fontSize: 12, color: kTextMid)),
            const SizedBox(height: 8),
            Text(
              routine.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: kTextMid),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: kTextLight),
                const SizedBox(width: 4),
                Text('${routine.adoptedCount}',
                    style: const TextStyle(fontSize: 12, color: kTextLight)),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(routine.avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, color: kTextLight)),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: adopting ? null : onAdopt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: adopting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Adopt',
                            style: TextStyle(fontSize: 13)),
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
