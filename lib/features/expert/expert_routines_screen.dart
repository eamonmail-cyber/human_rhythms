import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/library_routine.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/library_repo.dart';
import '../../features/auth/auth_controller.dart';
import '../../providers/global.dart';

// ── Expert specialties ────────────────────────────────────────────────────────

const _specialties = [
  'All Experts',
  'Medical Doctor',
  'Physiotherapist',
  'Nutritionist',
  'Psychologist',
  'Personal Trainer',
  'Specialist',
];

// ── Providers ─────────────────────────────────────────────────────────────────

final _expertRoutinesProvider =
    FutureProvider.family<List<LibraryRoutine>, String?>(
        (ref, specialty) async {
  final repo = ref.read(libraryRepoProvider);
  final all = await repo.getRoutines(
    expertsOnly: true,
    limit: 40,
  );
  if (specialty == null || specialty == 'All Experts') return all;
  return all
      .where((r) =>
          r.expertSpecialty?.toLowerCase() == specialty.toLowerCase())
      .toList();
});

final _expertProfilesProvider =
    FutureProvider.family<Map<String, PublicProfile>, List<String>>(
        (ref, authorIds) async {
  if (authorIds.isEmpty) return {};
  final repo = ref.read(libraryRepoProvider);
  final profiles = await Future.wait(
    authorIds.map((id) => repo.getProfile(id)),
  );
  final map = <String, PublicProfile>{};
  for (var i = 0; i < authorIds.length; i++) {
    final p = profiles[i];
    if (p != null) map[authorIds[i]] = p;
  }
  return map;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ExpertRoutinesScreen extends ConsumerStatefulWidget {
  const ExpertRoutinesScreen({super.key});
  @override
  ConsumerState<ExpertRoutinesScreen> createState() =>
      _ExpertRoutinesScreenState();
}

class _ExpertRoutinesScreenState
    extends ConsumerState<ExpertRoutinesScreen> {
  String _specialty = 'All Experts';

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final routinesAsync = ref.watch(_expertRoutinesProvider(_specialty));

    return AppScaffold(
      title: 'Expert Routines',
      body: Column(
        children: [
          // Specialty filter
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              children: _specialties.map((s) {
                final sel = s == _specialty;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _specialty = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? kPrimary : kDivider,
                            width: 1.5),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : kTextMid),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Routines list
          Expanded(
            child: RefreshIndicator(
              color: kPrimary,
              onRefresh: () async =>
                  ref.invalidate(_expertRoutinesProvider(_specialty)),
              child: routinesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: kPrimary)),
                error: (_, __) => ListView(children: [
                  _FriendlyEmpty(
                      icon: Icons.verified_outlined,
                      title: 'No Expert Routines Yet',
                      subtitle:
                          'Verified practitioner routines coming soon'),
                ]),
                data: (routines) {
                  if (routines.isEmpty) {
                    return ListView(children: [
                      _FriendlyEmpty(
                          icon: Icons.verified_outlined,
                          title: 'No Expert Routines Yet',
                          subtitle:
                              'Verified practitioner routines coming soon'),
                    ]);
                  }
                  // Fetch profiles for all unique authors
                  final authorIds =
                      routines.map((r) => r.authorId).toSet().toList();
                  return _RoutinesList(
                    routines: routines,
                    authorIds: authorIds,
                    userId: userId,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Routines list with profiles ───────────────────────────────────────────────

class _RoutinesList extends ConsumerWidget {
  final List<LibraryRoutine> routines;
  final List<String> authorIds;
  final String? userId;
  const _RoutinesList(
      {required this.routines,
      required this.authorIds,
      required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync =
        ref.watch(_expertProfilesProvider(authorIds));
    final profiles = profilesAsync.valueOrNull ?? {};

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: routines.length,
      itemBuilder: (_, i) {
        final r = routines[i];
        final profile = profiles[r.authorId];
        return _ExpertRoutineCard(
          routine: r,
          profile: profile,
          userId: userId,
        );
      },
    );
  }
}

// ── Expert routine card ───────────────────────────────────────────────────────

class _ExpertRoutineCard extends ConsumerWidget {
  final LibraryRoutine routine;
  final PublicProfile? profile;
  final String? userId;
  const _ExpertRoutineCard(
      {required this.routine, this.profile, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expert avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: kPrimary.withOpacity(0.12),
                    backgroundImage: routine.authorAvatarUrl != null
                        ? NetworkImage(routine.authorAvatarUrl!)
                        : null,
                    child: routine.authorAvatarUrl == null
                        ? Text(
                            routine.authorName.isNotEmpty
                                ? routine.authorName[0].toUpperCase()
                                : 'E',
                            style: const TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(routine.authorName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: kTextDark)),
                            const SizedBox(width: 6),
                            // Verified badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 10,
                                      color: Colors.white),
                                  SizedBox(width: 3),
                                  Text('Verified',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (routine.expertSpecialty != null)
                          Text(routine.expertSpecialty!,
                              style: const TextStyle(
                                  fontSize: 11, color: kTextLight)),
                        if (routine.expertCredential != null)
                          Text(routine.expertCredential!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: kTextMid,
                                  fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  // Adopted count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${routine.adoptedCount}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                              fontSize: 16)),
                      const Text('adopted',
                          style: TextStyle(
                              fontSize: 10, color: kTextLight)),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: kDivider),
            ),

            // Routine details
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(routine.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 10),
                  // Chips row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Chip(routine.category,
                          color: kPrimary.withOpacity(0.08),
                          textColor: kPrimary),
                      _Chip(routine.frequency,
                          color: kSurface, textColor: kTextMid),
                      ...routine.tags
                          .take(2)
                          .map((t) => _Chip(t,
                              color: kSurface, textColor: kTextMid)),
                    ],
                  ),

                  // Evidence note
                  if (routine.evidenceNote != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9575CD).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF9575CD)
                                .withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.science_outlined,
                              size: 14,
                              color: Color(0xFF9575CD)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              routine.evidenceNote!,
                              style: const TextStyle(
                                  fontSize: 12, color: kTextMid),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Rating
                  if (routine.ratingCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFFFB300)),
                        const SizedBox(width: 4),
                        Text(
                          '${routine.avgRating.toStringAsFixed(1)} (${routine.ratingCount} ratings)',
                          style: const TextStyle(
                              fontSize: 12, color: kTextMid),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Expert profile expansion
            if (profile != null && profile?.bio != null)
              _ExpertProfileExpander(profile: profile!),

            // Adopt button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: userId == null
                      ? null
                      : () => _adopt(context, ref, userId!),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add to My Routines'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adopt(
      BuildContext context, WidgetRef ref, String userId) async {
    try {
      await ref.read(libraryRepoProvider).adoptRoutine(
            libraryRoutineId: routine.id,
            userId: userId,
            routine: routine,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: kPrimary,
          content: Text('"${routine.title}" added to your routines!',
              style: const TextStyle(color: Colors.white)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to adopt routine.')));
      }
    }
  }
}

// ── Expert profile expander ───────────────────────────────────────────────────

class _ExpertProfileExpander extends StatefulWidget {
  final PublicProfile profile;
  const _ExpertProfileExpander({required this.profile});

  @override
  State<_ExpertProfileExpander> createState() =>
      _ExpertProfileExpanderState();
}

class _ExpertProfileExpanderState
    extends State<_ExpertProfileExpander> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Text(
                  'About the expert',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPrimary),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: kPrimary,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.profile.expertSpecialty != null)
                    Text(
                      widget.profile.expertSpecialty!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                          fontSize: 13),
                    ),
                  if (widget.profile.expertCredential != null)
                    Text(
                      widget.profile.expertCredential!,
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: kTextMid),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    widget.profile.bio!,
                    style: const TextStyle(
                        fontSize: 13, color: kTextDark),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded,
                          size: 13, color: kTextLight),
                      const SizedBox(width: 4),
                      Text(
                          '${widget.profile.followersCount} followers',
                          style: const TextStyle(
                              fontSize: 12, color: kTextMid)),
                      const SizedBox(width: 16),
                      const Icon(Icons.loop_rounded,
                          size: 13, color: kTextLight),
                      const SizedBox(width: 4),
                      Text(
                          '${widget.profile.publicRoutinesCount} routines',
                          style: const TextStyle(
                              fontSize: 12, color: kTextMid)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Chip(this.label,
      {required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kDivider),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor)),
      );
}

class _FriendlyEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FriendlyEmpty(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: kPrimary.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: kTextLight)),
          ],
        ),
      );
}

class _CentredMsg extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CentredMsg({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[500])),
          ],
        ),
      );
}
