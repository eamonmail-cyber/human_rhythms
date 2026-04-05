import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/enums.dart';
import '../../data/models/group.dart';
import '../../data/repositories/groups_repo.dart';
import '../../features/auth/auth_controller.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final groupsRepoProvider = Provider((_) => GroupsRepo());

final myGroupsProvider =
    FutureProvider.family<List<Group>, String>((ref, userId) {
  return ref.read(groupsRepoProvider).groupsForUser(userId);
});

final discoverGroupsProvider =
    FutureProvider.family<List<Group>, WellnessGoal?>((ref, goal) {
  return ref.read(groupsRepoProvider).discoverGroups(goal: goal);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});
  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  WellnessGoal? _selectedGoal; // null = All

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
      title: 'Wellness Groups',
      actions: [
        IconButton(
          icon: const Icon(Icons.people_outline_rounded),
          tooltip: 'Community',
          onPressed: () => context.push('/community'),
        ),
      ],
      body: userId == null
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Column(
              children: [
                _TabBar(controller: _tabs),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _MyGroupsTab(userId: userId),
                      _DiscoverTab(
                        selectedGoal: _selectedGoal,
                        onGoalChanged: (g) =>
                            setState(() => _selectedGoal = g),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: userId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Group',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _showCreateSheet(context, userId!),
            ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, String userId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateGroupSheet(userId: userId),
    );
    ref.invalidate(myGroupsProvider(userId));
    ref.invalidate(discoverGroupsProvider(_selectedGoal));
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurface,
      child: TabBar(
        controller: controller,
        labelColor: kPrimary,
        unselectedLabelColor: kTextLight,
        indicatorColor: kPrimary,
        indicatorWeight: 2,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [Tab(text: 'My Groups'), Tab(text: 'Discover')],
      ),
    );
  }
}

// ── My Groups tab ─────────────────────────────────────────────────────────────

class _MyGroupsTab extends ConsumerWidget {
  final String userId;
  const _MyGroupsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myGroupsProvider(userId));
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => ref.invalidate(myGroupsProvider(userId)),
      child: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (_, __) => ListView(children: [
          _FriendlyEmpty(
              icon: Icons.group_outlined,
              title: 'No Groups Yet',
              subtitle: 'Wellness groups are coming soon'),
        ]),
        data: (groups) => groups.isEmpty
            ? ListView(children: [
                const SizedBox(height: 24),
                _EmptyMyGroups(),
              ])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: groups.length,
                itemBuilder: (_, i) => _GroupCard(
                  group: groups[i],
                  isMember: true,
                  onTap: () => context.push('/groups/${groups[i].id}'),
                ),
              ),
      ),
    );
  }
}

// ── Discover tab ──────────────────────────────────────────────────────────────

class _DiscoverTab extends ConsumerWidget {
  final WellnessGoal? selectedGoal;
  final ValueChanged<WellnessGoal?> onGoalChanged;
  const _DiscoverTab(
      {required this.selectedGoal, required this.onGoalChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(discoverGroupsProvider(selectedGoal));
    return Column(
      children: [
        // Goal filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _GoalChip(
                label: 'All',
                emoji: '🌐',
                selected: selectedGoal == null,
                onTap: () => onGoalChanged(null),
              ),
              ...WellnessGoal.values.map((g) => _GoalChip(
                    label: wellnessGoalLabel(g),
                    emoji: wellnessGoalEmoji(g),
                    selected: selectedGoal == g,
                    onTap: () => onGoalChanged(g),
                  )),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: kPrimary,
            onRefresh: () async =>
                ref.invalidate(discoverGroupsProvider(selectedGoal)),
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: kPrimary)),
              error: (_, __) => ListView(children: [
                _FriendlyEmpty(
                    icon: Icons.group_outlined,
                    title: 'No Groups Yet',
                    subtitle: 'Wellness groups are coming soon'),
              ]),
              data: (groups) => groups.isEmpty
                  ? ListView(children: [
                      _FriendlyEmpty(
                          icon: Icons.group_outlined,
                          title: 'No Groups Yet',
                          subtitle: 'Wellness groups are coming soon'),
                    ])
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: groups.length,
                      itemBuilder: (_, i) => _GroupCard(
                        group: groups[i],
                        isMember: false,
                        onTap: () =>
                            context.push('/groups/${groups[i].id}'),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Goal chip ─────────────────────────────────────────────────────────────────

class _GoalChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _GoalChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : kTextMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Group card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final Group group;
  final bool isMember;
  final VoidCallback onTap;
  const _GroupCard(
      {required this.group,
      required this.isMember,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kDivider),
          ),
          child: Row(
            children: [
              // Goal avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(wellnessGoalEmoji(group.goalCategory),
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (group.description != null) ...[
                      const SizedBox(height: 2),
                      Text(group.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Goal chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            wellnessGoalLabel(group.goalCategory),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.people_outline_rounded,
                            size: 13, color: kTextLight),
                        const SizedBox(width: 3),
                        Text('${group.memberCount}',
                            style: const TextStyle(
                                fontSize: 12, color: kTextMid)),
                        if (group.isAnonymousAllowed) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.visibility_off_outlined,
                              size: 12, color: kTextLight),
                          const SizedBox(width: 3),
                          const Text('Anon OK',
                              style: TextStyle(
                                  fontSize: 10, color: kTextLight)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isMember
                    ? Icons.chevron_right_rounded
                    : Icons.add_circle_outline_rounded,
                color: isMember ? kTextLight : kAccent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyMyGroups extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded, size: 40, color: kPrimary),
            const SizedBox(height: 12),
            Text('No groups yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Tap Discover to find a group, or create your own to share your wellness journey.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Padding(
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
}

// ── Create group sheet ────────────────────────────────────────────────────────

class _CreateGroupSheet extends ConsumerStatefulWidget {
  final String userId;
  const _CreateGroupSheet({required this.userId});
  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  WellnessGoal _goal = WellnessGoal.generalFitness;
  bool _anonAllowed = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a group name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(groupsRepoProvider);
      final group = await repo.createGroup(
        name: name,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        goalCategory: _goal,
        userId: widget.userId,
        isAnonymousAllowed: _anonAllowed,
      );
      if (mounted) {
        Navigator.of(context).pop();
        context.push('/groups/${group.id}');
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
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
      child: SingleChildScrollView(
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
            Text('Create a Wellness Group',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Group name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)'),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 150,
            ),
            const SizedBox(height: 4),
            Text('WELLNESS GOAL',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: WellnessGoal.values.map((g) {
                final sel = g == _goal;
                return GestureDetector(
                  onTap: () => setState(() => _goal = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? kPrimary : kSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? kPrimary : kDivider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(wellnessGoalEmoji(g),
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          wellnessGoalLabel(g),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : kTextMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Anonymous toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allow anonymous posts',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text('Members can post without showing their name',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _anonAllowed,
                  activeColor: kPrimary,
                  onChanged: (v) => setState(() => _anonAllowed = v),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style:
                      const TextStyle(color: kAccent, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
