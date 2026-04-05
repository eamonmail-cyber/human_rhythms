import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/challenge.dart';
import '../../data/models/enums.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/challenges_repo.dart';
import '../../data/repositories/library_repo.dart';
import '../../features/auth/auth_controller.dart';
import 'challenges_screen.dart'
    show challengesRepoProvider, catColor, catEmoji;

// ── Providers ─────────────────────────────────────────────────────────────────

final _challengeProvider =
    FutureProvider.family<Challenge?, String>((ref, id) {
  return ref.read(challengesRepoProvider).getChallenge(id);
});

final _participantProvider =
    FutureProvider.family<ChallengeParticipant?, _PKey>((ref, key) {
  return ref
      .read(challengesRepoProvider)
      .getParticipant(key.challengeId, key.userId);
});

final _leaderboardProvider =
    FutureProvider.family<List<ChallengeParticipant>, String>((ref, id) {
  return ref.read(challengesRepoProvider).getLeaderboard(id);
});

final _feedProvider =
    FutureProvider.family<List<ChallengeCheckin>, String>((ref, id) {
  return ref.read(challengesRepoProvider).getCommunityFeed(id);
});

class _PKey {
  final String challengeId;
  final String userId;
  const _PKey(this.challengeId, this.userId);
  @override
  bool operator ==(Object o) =>
      o is _PKey &&
      o.challengeId == challengeId &&
      o.userId == userId;
  @override
  int get hashCode => Object.hash(challengeId, userId);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ChallengeDetailScreen extends ConsumerWidget {
  final String challengeId;
  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    final challengeAsync = ref.watch(_challengeProvider(challengeId));

    return challengeAsync.when(
      loading: () => const AppScaffold(
          title: '',
          showBack: true,
          body: Center(
              child: CircularProgressIndicator(color: kPrimary))),
      error: (_, __) => const AppScaffold(
          title: 'Challenge',
          showBack: true,
          body: Center(child: Text('Could not load challenge.'))),
      data: (challenge) {
        if (challenge == null) {
          return const AppScaffold(
              title: 'Challenge',
              showBack: true,
              body: Center(child: Text('Challenge not found.')));
        }
        return AppScaffold(
          title: challenge.title,
          showBack: true,
          body: userId == null
              ? const Center(
                  child: CircularProgressIndicator(color: kPrimary))
              : _Body(
                  challenge: challenge,
                  userId: userId,
                  challengeId: challengeId,
                ),
        );
      },
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerStatefulWidget {
  final Challenge challenge;
  final String userId;
  final String challengeId;
  const _Body(
      {required this.challenge,
      required this.userId,
      required this.challengeId});
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _invalidate() {
    ref.invalidate(_challengeProvider(widget.challengeId));
    ref.invalidate(
        _participantProvider(_PKey(widget.challengeId, widget.userId)));
    ref.invalidate(_leaderboardProvider(widget.challengeId));
    ref.invalidate(_feedProvider(widget.challengeId));
  }

  @override
  Widget build(BuildContext context) {
    final participantAsync = ref.watch(
        _participantProvider(_PKey(widget.challengeId, widget.userId)));
    final participant = participantAsync.valueOrNull;

    return Column(
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        _Header(
          challenge: widget.challenge,
          participant: participant,
          userId: widget.userId,
          onJoinLeave: _invalidate,
          onCheckIn: _handleCheckIn,
        ),

        // ── Tabs ───────────────────────────────────────────────────────────
        // Use participant != null directly so Dart can promote the local
        // variable to non-nullable inside this block.
        if (participant != null) ...[
          Container(
            color: kSurface,
            child: TabBar(
              controller: _tabs,
              labelColor: kPrimary,
              unselectedLabelColor: kTextLight,
              indicatorColor: kPrimary,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
              tabs: const [
                Tab(text: 'Community'),
                Tab(text: 'Leaderboard'),
                Tab(text: 'My Progress'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _CommunityFeedTab(challengeId: widget.challengeId),
                _LeaderboardTab(
                    challengeId: widget.challengeId,
                    userId: widget.userId),
                _MyProgressTab(
                    challenge: widget.challenge,
                    participant: participant),
              ],
            ),
          ),
        ] else
          Expanded(
            child: _CommunityFeedTab(
                challengeId: widget.challengeId),
          ),
      ],
    );
  }

  Future<void> _handleCheckIn(Challenge challenge,
      ChallengeParticipant participant) async {
    if (participant.checkedInToday) return;

    // Haptic: single pulse for regular check-in
    await HapticFeedback.lightImpact();

    final repo = ref.read(challengesRepoProvider);
    final updated = await repo.checkIn(
      challengeId: widget.challengeId,
      userId: widget.userId,
    );

    // Milestone haptics
    if (milestoneDays.contains(updated.totalCheckins)) {
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.mediumImpact();
    }

    // Challenge complete haptic
    if (updated.totalCheckins >= challenge.durationDays) {
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
      if (mounted) _showCompletionDialog(challenge, updated);
    } else if (milestoneDays.contains(updated.totalCheckins) && mounted) {
      _showMilestoneSnackbar(updated.totalCheckins);
    }

    _invalidate();
  }

  void _showMilestoneSnackbar(int day) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: kPrimary,
      content: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text('Day $day milestone reached!',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showCompletionDialog(
      Challenge challenge, ChallengeParticipant participant) {
    final pct =
        participant.completionFraction(challenge.durationDays) * 100;
    final groupPct = challenge.completionRate * 100;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🏆 ', style: TextStyle(fontSize: 24)),
            Text('Challenge Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You finished ${challenge.title}!',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _StatRow(
                label: 'Your completion',
                value: '${pct.round()}%',
                color: kPrimary),
            const SizedBox(height: 8),
            _StatRow(
                label: 'Group average',
                value: '${groupPct.round()}%',
                color: kTextMid),
            const SizedBox(height: 16),
            Text(
              pct >= groupPct
                  ? 'You beat the group average! Keep the momentum going.'
                  : 'Every check-in counts. Come back stronger next time!',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _shareToStories(challenge, participant);
            },
            child: const Text('Share to Stories'),
          ),
        ],
      ),
    );
  }

  void _shareToStories(
      Challenge challenge, ChallengeParticipant participant) async {
    final pct =
        (participant.completionFraction(challenge.durationDays) * 100)
            .round();
    final story = RoutineStory(
      id: '${widget.userId}_${widget.challengeId}',
      authorId: widget.userId,
      authorName: challengeAliasFor(widget.userId),
      authorAge: 0,
      title:
          'I completed the ${challenge.title} challenge!',
      beforeDescription:
          'Before starting this challenge, I wanted to improve my ${challenge.goal}.',
      afterDescription:
          'After ${challenge.durationDays} days, I hit $pct% completion and built a real habit.',
      routineId: widget.challengeId,
      routineTitle: challenge.title,
      durationWeeks: (challenge.durationDays / 7).ceil(),
      improvements: [challenge.goal],
      isAnonymous: true,
      createdAt: DateTime.now(),
    );
    try {
      final repo = LibraryRepo();
      await repo.publishStory(story);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: kPrimary,
          content: Text('Story shared!',
              style: TextStyle(color: Colors.white)),
        ));
      }
    } catch (_) {}
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final Challenge challenge;
  final ChallengeParticipant? participant;
  final String userId;
  final VoidCallback onJoinLeave;
  final Future<void> Function(Challenge, ChallengeParticipant) onCheckIn;

  const _Header({
    required this.challenge,
    required this.participant,
    required this.userId,
    required this.onJoinLeave,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create a local copy so Dart's flow analysis can promote the nullable
    // public field to non-nullable inside null-check guards.
    final participant = this.participant;
    final color = catColor(challenge.category);
    final checkedIn = participant?.checkedInToday ?? false;
    final currentDay = challenge.daysSinceStart + 1;
    final nudge =
        challengeNudgeForDay(participant?.totalCheckins ?? 0);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge info
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(catEmoji(challenge.category),
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.goal,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 13, color: kTextLight),
                        const SizedBox(width: 3),
                        Text('${challenge.participantCount} joined',
                            style: const TextStyle(
                                fontSize: 12, color: kTextMid)),
                        const SizedBox(width: 12),
                        const Icon(Icons.trending_up_rounded,
                            size: 13, color: kTextLight),
                        const SizedBox(width: 3),
                        Text(
                            '${(challenge.completionRate * 100).round()}% avg',
                            style: const TextStyle(
                                fontSize: 12, color: kTextMid)),
                      ],
                    ),
                  ],
                ),
              ),
              // Day counter
              if (participant != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Day $currentDay',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: color),
                    ),
                    Text(
                      'of ${challenge.durationDays}',
                      style: const TextStyle(
                          fontSize: 12, color: kTextLight),
                    ),
                  ],
                ),
            ],
          ),

          // Progress bar (if participating) — participant is promoted to
          // non-nullable inside this if (participant != null) guard.
          if (participant != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${participant.totalCheckins} check-ins · ${participant.currentStreak} day streak 🔥',
                  style: const TextStyle(
                      fontSize: 12, color: kTextMid),
                ),
                Text(
                  '${(participant.completionFraction(challenge.durationDays) * 100).round()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: participant.completionFraction(challenge.durationDays),
                minHeight: 7,
                backgroundColor: kDivider,
                color: color,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action button
          SizedBox(
            width: double.infinity,
            child: participant != null
                ? checkedIn
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: kPrimary),
                        label: const Text('Done for today',
                            style: TextStyle(color: kPrimary)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kPrimary)),
                      )
                    : ElevatedButton.icon(
                        onPressed: () =>
                            onCheckIn(challenge, participant),
                        icon: const Icon(Icons.check_rounded,
                            size: 16),
                        label: const Text('Check In Today'),
                      )
                : ElevatedButton.icon(
                    onPressed: () => _join(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Join Challenge'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent),
                  ),
          ),

          // Mindset nudge
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimary.withOpacity(0.08),
                  kAccent.withOpacity(0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nudge,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: kPrimary,
                            fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(challengesRepoProvider);
    await repo.joinChallenge(
      challengeId: challenge.id,
      userId: userId,
      challengeTitle: challenge.title,
      category: challenge.category,
    );
    onJoinLeave();
  }
}

// ── Community feed tab ────────────────────────────────────────────────────────

class _CommunityFeedTab extends ConsumerWidget {
  final String challengeId;
  const _CommunityFeedTab({required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_feedProvider(challengeId));
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => ref.invalidate(_feedProvider(challengeId)),
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (_, __) => ListView(children: [
          _CentredMsg(
              icon: Icons.cloud_off_outlined,
              text: 'Could not load activity.'),
        ]),
        data: (checkins) => checkins.isEmpty
            ? ListView(children: [
                _CentredMsg(
                    icon: Icons.auto_awesome_outlined,
                    text: 'No check-ins yet.\nBe the first!'),
              ])
            : ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: checkins.length,
                itemBuilder: (_, i) =>
                    _CheckinCard(checkin: checkins[i]),
              ),
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  final ChallengeCheckin checkin;
  const _CheckinCard({required this.checkin});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kDivider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: kPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(checkin.alias,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: kTextDark)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('checked in',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimary)),
                        ),
                        const Spacer(),
                        Text(_timeAgo(checkin.date),
                            style: const TextStyle(
                                fontSize: 11, color: kTextLight)),
                      ],
                    ),
                    if (checkin.note != null) ...[
                      const SizedBox(height: 4),
                      Text(checkin.note!,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Leaderboard tab ───────────────────────────────────────────────────────────

class _LeaderboardTab extends ConsumerStatefulWidget {
  final String challengeId;
  final String userId;
  const _LeaderboardTab(
      {required this.challengeId, required this.userId});
  @override
  ConsumerState<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<_LeaderboardTab> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_leaderboardProvider(widget.challengeId));
    final participantAsync = ref.watch(
        _participantProvider(_PKey(widget.challengeId, widget.userId)));
    final showOnLb =
        participantAsync.valueOrNull?.showOnLeaderboard ?? true;

    return Column(
      children: [
        // Opt-out toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Show me on leaderboard',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Switch(
                value: showOnLb,
                activeColor: kPrimary,
                onChanged: (v) async {
                  await ref
                      .read(challengesRepoProvider)
                      .setLeaderboardVisibility(
                          widget.challengeId, widget.userId, v);
                  ref.invalidate(_participantProvider(
                      _PKey(widget.challengeId, widget.userId)));
                  ref.invalidate(
                      _leaderboardProvider(widget.challengeId));
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: kPrimary,
            onRefresh: () async =>
                ref.invalidate(_leaderboardProvider(widget.challengeId)),
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: kPrimary)),
              error: (_, __) => ListView(children: [
                _CentredMsg(
                    icon: Icons.cloud_off_outlined,
                    text: 'Could not load leaderboard.'),
              ]),
              data: (entries) => entries.isEmpty
                  ? ListView(children: [
                      _CentredMsg(
                          icon: Icons.people_outline_rounded,
                          text: 'No one on the leaderboard yet.'),
                    ])
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: entries.length,
                      itemBuilder: (_, i) =>
                          _LeaderboardRow(rank: i + 1, p: entries[i]),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final ChallengeParticipant p;
  const _LeaderboardRow({required this.rank, required this.p});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: rank <= 3
                ? kPrimary.withOpacity(rank == 1 ? 0.1 : 0.05)
                : kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color:
                    rank <= 3 ? kPrimary.withOpacity(0.2) : kDivider),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  rank <= 3
                      ? ['🥇', '🥈', '🥉'][rank - 1]
                      : '$rank',
                  style: TextStyle(
                      fontSize: rank <= 3 ? 18 : 14,
                      fontWeight: FontWeight.w700,
                      color: kTextMid),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(p.alias,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              Text(
                '${p.totalCheckins} days',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                    fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '🔥 ${p.currentStreak}',
                style: const TextStyle(
                    fontSize: 13, color: kTextMid),
              ),
            ],
          ),
        ),
      );
}

// ── My progress tab ───────────────────────────────────────────────────────────

class _MyProgressTab extends StatelessWidget {
  final Challenge challenge;
  final ChallengeParticipant participant;
  const _MyProgressTab(
      {required this.challenge, required this.participant});

  @override
  Widget build(BuildContext context) {
    final myPct = participant
        .completionFraction(challenge.durationDays);
    final groupPct = challenge.completionRate;
    final dayElapsed = challenge.daysSinceStart;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Progress',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _StatRow(
                  label: 'Total check-ins',
                  value: '${participant.totalCheckins}',
                  color: kPrimary),
              const SizedBox(height: 10),
              _StatRow(
                  label: 'Current streak',
                  value: '${participant.currentStreak} 🔥',
                  color: kAccent),
              const SizedBox(height: 10),
              _StatRow(
                  label: 'Your completion',
                  value: '${(myPct * 100).round()}%',
                  color: kPrimary),
              const SizedBox(height: 10),
              _StatRow(
                  label: 'Group average',
                  value: '${(groupPct * 100).round()}%',
                  color: kTextMid),
              const SizedBox(height: 16),
              // Day timeline
              Text('${dayElapsed} of ${challenge.durationDays} days elapsed',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: challenge.durationDays == 0
                      ? 0
                      : dayElapsed / challenge.durationDays,
                  minHeight: 8,
                  backgroundColor: kDivider,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Milestone chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: milestoneDays.map((d) {
                  final reached = participant.totalCheckins >= d;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: reached
                          ? kPrimary.withOpacity(0.1)
                          : kSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: reached ? kPrimary : kDivider),
                    ),
                    child: Text(
                      reached ? '✅ Day $d' : 'Day $d',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: reached ? kPrimary : kTextLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 14)),
        ],
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

String _timeAgo(DateTime dt) {
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays == 1) return 'yesterday';
  return '${d.inDays}d ago';
}
