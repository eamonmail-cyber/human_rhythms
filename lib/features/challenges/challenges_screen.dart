import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/challenge.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/challenges_repo.dart';
import '../../features/auth/auth_controller.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final challengesRepoProvider = Provider((_) => ChallengesRepo());

final activeChallengesProvider =
    FutureProvider.family<List<Challenge>, RoutineCategory?>(
        (ref, cat) async {
  final repo = ref.read(challengesRepoProvider);
  return cat == null
      ? repo.getActive()
      : repo.getByCategory(cat);
});

final myChallengesProvider =
    FutureProvider.family<List<Challenge>, String>((ref, userId) {
  return ref.read(challengesRepoProvider).challengesForUser(userId);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});
  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  RoutineCategory? _filter;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    return AppScaffold(
      title: '30-Day Challenges',
      body: userId == null
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Column(
              children: [
                _TabBar(controller: _tabs),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _BrowseTab(
                        filter: _filter,
                        onFilterChanged: (c) =>
                            setState(() => _filter = c),
                        userId: userId,
                      ),
                      _MyChallengesTab(userId: userId),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
        color: kSurface,
        child: TabBar(
          controller: controller,
          labelColor: kPrimary,
          unselectedLabelColor: kTextLight,
          indicatorColor: kPrimary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: 'Browse'), Tab(text: 'My Challenges')],
        ),
      );
}

// ── Browse tab ────────────────────────────────────────────────────────────────

class _BrowseTab extends ConsumerWidget {
  final RoutineCategory? filter;
  final ValueChanged<RoutineCategory?> onFilterChanged;
  final String userId;
  const _BrowseTab(
      {required this.filter,
      required this.onFilterChanged,
      required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeChallengesProvider(filter));
    return Column(
      children: [
        // Category filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _FilterChip(
                label: 'All',
                emoji: '🌐',
                selected: filter == null,
                onTap: () => onFilterChanged(null),
              ),
              ...RoutineCategory.values.map((c) => _FilterChip(
                    label: _catLabel(c),
                    emoji: catEmoji(c),
                    selected: filter == c,
                    onTap: () => onFilterChanged(c),
                  )),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: kPrimary,
            onRefresh: () async =>
                ref.invalidate(activeChallengesProvider(filter)),
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: kPrimary)),
              error: (_, __) => ListView(children: [
                _FriendlyEmpty(
                    icon: Icons.emoji_events_outlined,
                    title: 'No Challenges Yet',
                    subtitle:
                        'Check back soon for 30-day challenges to join'),
              ]),
              data: (challenges) => challenges.isEmpty
                  ? ListView(children: [
                      _FriendlyEmpty(
                          icon: Icons.emoji_events_outlined,
                          title: 'No Challenges Yet',
                          subtitle:
                              'Check back soon for 30-day challenges to join'),
                    ])
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: challenges.length,
                      itemBuilder: (_, i) => _ChallengeCard(
                        challenge: challenges[i],
                        userId: userId,
                        onTap: () => context
                            .push('/challenges/${challenges[i].id}'),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── My challenges tab ─────────────────────────────────────────────────────────

class _MyChallengesTab extends ConsumerWidget {
  final String userId;
  const _MyChallengesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myChallengesProvider(userId));
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => ref.invalidate(myChallengesProvider(userId)),
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (_, __) => ListView(children: [
          _FriendlyEmpty(
              icon: Icons.emoji_events_outlined,
              title: 'No Challenges Yet',
              subtitle:
                  'Check back soon for 30-day challenges to join'),
        ]),
        data: (challenges) => challenges.isEmpty
            ? ListView(children: [
                const SizedBox(height: 24),
                _EmptyMyChallenges(),
              ])
            : ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: challenges.length,
                itemBuilder: (_, i) => _ChallengeCard(
                  challenge: challenges[i],
                  userId: userId,
                  onTap: () => context
                      .push('/challenges/${challenges[i].id}'),
                ),
              ),
      ),
    );
  }
}

// ── Challenge card ────────────────────────────────────────────────────────────

class _ChallengeCard extends ConsumerWidget {
  final Challenge challenge;
  final String userId;
  final VoidCallback onTap;
  const _ChallengeCard(
      {required this.challenge,
      required this.userId,
      required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = catColor(challenge.category);
    final pct = challenge.completionRate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(catEmoji(challenge.category),
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(challenge.title,
                            style:
                                Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(challenge.goal,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: kTextLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${challenge.durationDays}d',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                      const Text('challenge',
                          style: TextStyle(
                              fontSize: 10, color: kTextLight)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats row
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded,
                      size: 13, color: kTextLight),
                  const SizedBox(width: 4),
                  Text('${challenge.participantCount} joined',
                      style: const TextStyle(
                          fontSize: 12, color: kTextMid)),
                  const SizedBox(width: 16),
                  const Icon(Icons.trending_up_rounded,
                      size: 13, color: kTextLight),
                  const SizedBox(width: 4),
                  Text(
                      '${(pct * 100).round()}% avg completion',
                      style: const TextStyle(
                          fontSize: 12, color: kTextMid)),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: kDivider,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyMyChallenges extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kAccent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kAccent.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events_outlined,
                  size: 40, color: kAccent),
              const SizedBox(height: 12),
              Text('No challenges yet',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Browse active challenges and join one to start your 30-day journey.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.emoji,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? kPrimary : kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? kPrimary : kDivider, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : kTextMid)),
              ],
            ),
          ),
        ),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

Color catColor(RoutineCategory c) => switch (c) {
  RoutineCategory.sleep      => kCatSleep,
  RoutineCategory.movement   => kCatMovement,
  RoutineCategory.food       => kCatFood,
  RoutineCategory.mind       => kCatMind,
  RoutineCategory.social     => kCatSocial,
  RoutineCategory.work       => kCatWork,
  RoutineCategory.health     => kCatHealth,
  RoutineCategory.reflection => kCatReflection,
};

String catEmoji(RoutineCategory c) => switch (c) {
  RoutineCategory.sleep      => '😴',
  RoutineCategory.movement   => '🏃',
  RoutineCategory.food       => '🥗',
  RoutineCategory.mind       => '🧠',
  RoutineCategory.social     => '🤝',
  RoutineCategory.work       => '💼',
  RoutineCategory.health     => '❤️',
  RoutineCategory.reflection => '📔',
};

String _catLabel(RoutineCategory c) => switch (c) {
  RoutineCategory.sleep      => 'Sleep',
  RoutineCategory.movement   => 'Movement',
  RoutineCategory.food       => 'Food',
  RoutineCategory.mind       => 'Mind',
  RoutineCategory.social     => 'Social',
  RoutineCategory.work       => 'Work',
  RoutineCategory.health     => 'Health',
  RoutineCategory.reflection => 'Reflect',
};
