import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/enums.dart';
import '../../data/models/group.dart';
import '../../data/repositories/groups_repo.dart';
import '../../features/auth/auth_controller.dart';
import 'groups_screen.dart' show groupsRepoProvider;

// ── Providers ─────────────────────────────────────────────────────────────────

final _groupDetailProvider =
    FutureProvider.family<Group?, String>((ref, groupId) {
  return ref.read(groupsRepoProvider).getGroup(groupId);
});

final _activityProvider =
    FutureProvider.family<List<GroupActivity>, String>((ref, groupId) {
  return ref.read(groupsRepoProvider).getActivity(groupId);
});

final _membershipProvider =
    FutureProvider.family<bool, _MKey>((ref, key) {
  return ref.read(groupsRepoProvider).isMember(key.groupId, key.userId);
});

class _MKey {
  final String groupId;
  final String userId;
  const _MKey(this.groupId, this.userId);
  @override
  bool operator ==(Object o) =>
      o is _MKey && o.groupId == groupId && o.userId == userId;
  @override
  int get hashCode => Object.hash(groupId, userId);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    final groupAsync = ref.watch(_groupDetailProvider(groupId));

    return groupAsync.when(
      loading: () => const AppScaffold(
          title: '',
          showBack: true,
          body: Center(
              child: CircularProgressIndicator(color: kPrimary))),
      error: (_, __) => const AppScaffold(
          title: 'Group',
          showBack: true,
          body: Center(child: Text('Could not load group.'))),
      data: (group) {
        if (group == null) {
          return const AppScaffold(
              title: 'Group',
              showBack: true,
              body: Center(child: Text('Group not found.')));
        }
        return AppScaffold(
          title: group.name,
          showBack: true,
          body: userId == null
              ? const Center(
                  child: CircularProgressIndicator(color: kPrimary))
              : _Body(group: group, userId: userId, groupId: groupId),
        );
      },
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerStatefulWidget {
  final Group group;
  final String userId;
  final String groupId;
  const _Body(
      {required this.group, required this.userId, required this.groupId});
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  void _invalidateAll() {
    ref.invalidate(_activityProvider(widget.groupId));
    ref.invalidate(_membershipProvider(_MKey(widget.groupId, widget.userId)));
    ref.invalidate(_groupDetailProvider(widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync =
        ref.watch(_membershipProvider(_MKey(widget.groupId, widget.userId)));
    final activityAsync = ref.watch(_activityProvider(widget.groupId));
    final isMember = memberAsync.valueOrNull ?? false;

    return Stack(
      children: [
        RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _invalidateAll(),
          child: CustomScrollView(
            slivers: [
              // ── Mindset nudge ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _MindsetNudgeBanner(
                    groupId: widget.groupId),
              ),

              // ── Group header ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _GroupHeader(
                  group: widget.group,
                  userId: widget.userId,
                  memberAsync: memberAsync,
                  onJoinLeave: _invalidateAll,
                ),
              ),

              // ── Feed label ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Text('ANONYMOUS ACTIVITY',
                          style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      const Icon(Icons.lock_outline_rounded,
                          size: 12, color: kTextLight),
                      const SizedBox(width: 4),
                      const Text('Members only',
                          style: TextStyle(
                              fontSize: 11, color: kTextLight)),
                    ],
                  ),
                ),
              ),

              // ── Activity list ────────────────────────────────────────────
              activityAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                                color: kPrimary)))),
                error: (_, __) => SliverToBoxAdapter(
                    child: _CentredMsg(
                        icon: Icons.cloud_off_outlined,
                        text: "Couldn't load activity.\nPull to retry.")),
                data: (items) => items.isEmpty
                    ? SliverToBoxAdapter(
                        child: _CentredMsg(
                          icon: Icons.auto_awesome_outlined,
                          text:
                              'No posts yet.\nBe the first to share!',
                        ))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _ActivityCard(activity: items[i]),
                          childCount: items.length,
                        ),
                      ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),

        // ── Share FAB (only for members) ─────────────────────────────────
        if (isMember)
          Positioned(
            bottom: 16,
            right: 16,
            child: _ShareFab(
              group: widget.group,
              userId: widget.userId,
              onPosted: _invalidateAll,
            ),
          ),
      ],
    );
  }
}

// ── Mindset nudge banner ──────────────────────────────────────────────────────

class _MindsetNudgeBanner extends StatelessWidget {
  final String groupId;
  const _MindsetNudgeBanner({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final nudge = nudgeForGroup(groupId);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary.withOpacity(0.15), kAccent.withOpacity(0.08)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nudge,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: kPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Group header ──────────────────────────────────────────────────────────────

class _GroupHeader extends ConsumerWidget {
  final Group group;
  final String userId;
  final AsyncValue<bool> memberAsync;
  final VoidCallback onJoinLeave;

  const _GroupHeader({
    required this.group,
    required this.userId,
    required this.memberAsync,
    required this.onJoinLeave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(wellnessGoalEmoji(group.goalCategory),
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            wellnessGoalLabel(group.goalCategory),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.people_outline_rounded,
                            size: 13, color: kTextLight),
                        const SizedBox(width: 3),
                        Text('${group.memberCount} members',
                            style: const TextStyle(
                                fontSize: 12, color: kTextMid)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (group.description != null) ...[
            const SizedBox(height: 10),
            Text(group.description!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 14),
          memberAsync.when(
            loading: () => const SizedBox(
                height: 36,
                child: Center(
                    child: CircularProgressIndicator(
                        color: kPrimary, strokeWidth: 2))),
            error: (_, __) => const SizedBox.shrink(),
            data: (isMember) => SizedBox(
              width: double.infinity,
              child: isMember
                  ? OutlinedButton.icon(
                      onPressed: () => _confirmLeave(context, ref),
                      icon: const Icon(Icons.exit_to_app_rounded,
                          size: 16),
                      label: const Text('Leave Group'),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _join(ref),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Join Group'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          // Anonymity notice
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility_off_outlined,
                    size: 14, color: kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.isAnonymousAllowed
                        ? 'Activity is shared with your anonymous alias. Your identity is never revealed.'
                        : 'This group requires named posts.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12, color: kPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _join(WidgetRef ref) async {
    await ref.read(groupsRepoProvider).joinGroup(group.id, userId);
    onJoinLeave();
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group?'),
        content:
            Text('You will no longer see "${group.name}" activity.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Leave',
                  style: TextStyle(color: kAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(groupsRepoProvider).leaveGroup(group.id, userId);
      onJoinLeave();
    }
  }
}

// ── Share FAB ─────────────────────────────────────────────────────────────────

class _ShareFab extends StatelessWidget {
  final Group group;
  final String userId;
  final VoidCallback onPosted;
  const _ShareFab(
      {required this.group, required this.userId, required this.onPosted});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: kAccent,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_comment_outlined),
      label: const Text('Share',
          style: TextStyle(fontWeight: FontWeight.w700)),
      onPressed: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _PostSheet(group: group, userId: userId),
        );
        onPosted();
      },
    );
  }
}

// ── Activity card ─────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final GroupActivity activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _postStyle(activity.postType);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Icon(icon, size: 18, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(activity.alias,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: kTextDark)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _postTypeLabel(activity.postType),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(activity.timestamp),
                        style: const TextStyle(
                            fontSize: 11, color: kTextLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(activity.activityText,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _postStyle(GroupPostType t) => switch (t) {
    GroupPostType.activityLog => (Icons.check_circle_outline_rounded, kPrimary),
    GroupPostType.shareWin    => (Icons.emoji_events_outlined, kAccent),
    GroupPostType.question    => (Icons.help_outline_rounded, const Color(0xFF9575CD)),
  };

  String _postTypeLabel(GroupPostType t) => switch (t) {
    GroupPostType.activityLog => 'Activity',
    GroupPostType.shareWin    => 'Win',
    GroupPostType.question    => 'Question',
  };
}

// ── Post sheet ────────────────────────────────────────────────────────────────

class _PostSheet extends ConsumerStatefulWidget {
  final Group group;
  final String userId;
  const _PostSheet({required this.group, required this.userId});
  @override
  ConsumerState<_PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends ConsumerState<_PostSheet> {
  GroupPostType _postType = GroupPostType.activityLog;
  final _textCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  String get _hint => switch (_postType) {
    GroupPostType.activityLog =>
        '${aliasFor(widget.userId)} completed a routine...',
    GroupPostType.shareWin    =>
        '${aliasFor(widget.userId)} wants to share a win...',
    GroupPostType.question    =>
        '${aliasFor(widget.userId)} has a question...',
  };

  Future<void> _post() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(groupsRepoProvider).postActivity(
            groupId: widget.group.id,
            userId: widget.userId,
            postType: _postType,
            activityText: text,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to post. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
          color: kCard, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: kDivider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.visibility_off_outlined,
                  size: 16, color: kPrimary),
              const SizedBox(width: 8),
              Text('Post as ${aliasFor(widget.userId)}',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your name is never shown to other members.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: kTextLight),
          ),
          const SizedBox(height: 16),

          // Post type picker
          Row(
            children: GroupPostType.values.map((t) {
              final sel = t == _postType;
              final (icon, color) = _iconAndColor(t);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _postType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? color.withOpacity(0.1)
                            : kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? color : kDivider,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Column(
                        children: [
                          Icon(icon,
                              size: 20,
                              color: sel ? color : kTextLight),
                          const SizedBox(height: 4),
                          Text(
                            _postTypeLabel(t),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sel ? color : kTextLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          TextField(
            controller: _textCtrl,
            decoration: InputDecoration(hintText: _hint),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 280,
            maxLines: 3,
            minLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _post,
              style: ElevatedButton.styleFrom(backgroundColor: kAccent),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Post to Group'),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _iconAndColor(GroupPostType t) => switch (t) {
    GroupPostType.activityLog =>
        (Icons.check_circle_outline_rounded, kPrimary),
    GroupPostType.shareWin    =>
        (Icons.emoji_events_outlined, kAccent),
    GroupPostType.question    =>
        (Icons.help_outline_rounded, const Color(0xFF9575CD)),
  };

  String _postTypeLabel(GroupPostType t) => switch (t) {
    GroupPostType.activityLog => 'Activity',
    GroupPostType.shareWin    => 'Win',
    GroupPostType.question    => 'Question',
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
