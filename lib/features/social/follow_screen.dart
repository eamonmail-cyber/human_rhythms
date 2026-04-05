import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/social_models.dart';
import '../../providers/global.dart';

class FollowScreen extends ConsumerStatefulWidget {
  const FollowScreen({super.key});

  @override
  ConsumerState<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends ConsumerState<FollowScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<PublicProfile> _following = [];
  List<PublicProfile> _discover = [];
  bool _loadingFollowing = true;
  bool _loadingDiscover = true;
  final Set<String> _pending = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadFollowing();
    _loadDiscover();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadFollowing() async {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    if (!mounted) return;
    setState(() => _loadingFollowing = true);
    final list = await ref.read(libraryRepoProvider).getFollowing(uid);
    if (mounted) setState(() { _following = list; _loadingFollowing = false; });
  }

  Future<void> _loadDiscover() async {
    if (!mounted) return;
    setState(() => _loadingDiscover = true);
    final list = await ref.read(libraryRepoProvider).searchProfiles();
    if (mounted) setState(() { _discover = list; _loadingDiscover = false; });
  }

  bool _isFollowing(String uid) =>
      _following.any((p) => p.userId == uid);

  Future<void> _toggleFollow(PublicProfile profile) async {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    setState(() => _pending.add(profile.userId));
    final repo = ref.read(libraryRepoProvider);
    if (_isFollowing(profile.userId)) {
      await repo.unfollowUser(uid, profile.userId);
    } else {
      await repo.followUser(uid, profile.userId);
    }
    if (!mounted) return;
    setState(() => _pending.remove(profile.userId));
    _loadFollowing();
    _loadDiscover();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Community',
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            labelColor: kPrimary,
            unselectedLabelColor: kTextMid,
            indicatorColor: kPrimary,
            tabs: const [Tab(text: 'Discover'), Tab(text: 'Following')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _DiscoverTab(
                  profiles: _discover,
                  loading: _loadingDiscover,
                  isFollowing: _isFollowing,
                  pending: _pending,
                  onToggle: _toggleFollow,
                  onRefresh: _loadDiscover,
                ),
                _FollowingTab(
                  profiles: _following,
                  loading: _loadingFollowing,
                  pending: _pending,
                  onUnfollow: _toggleFollow,
                  onRefresh: _loadFollowing,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  final List<PublicProfile> profiles;
  final bool loading;
  final bool Function(String) isFollowing;
  final Set<String> pending;
  final void Function(PublicProfile) onToggle;
  final Future<void> Function() onRefresh;

  const _DiscoverTab({
    required this.profiles,
    required this.loading,
    required this.isFollowing,
    required this.pending,
    required this.onToggle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (profiles.isEmpty) {
      return const Center(
          child: Text('No profiles yet',
              style: TextStyle(color: kTextLight)));
    }
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: profiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ProfileCard(
          profile: profiles[i],
          following: isFollowing(profiles[i].userId),
          pending: pending.contains(profiles[i].userId),
          onToggle: () => onToggle(profiles[i]),
        ),
      ),
    );
  }
}

class _FollowingTab extends StatelessWidget {
  final List<PublicProfile> profiles;
  final bool loading;
  final Set<String> pending;
  final void Function(PublicProfile) onUnfollow;
  final Future<void> Function() onRefresh;

  const _FollowingTab({
    required this.profiles,
    required this.loading,
    required this.pending,
    required this.onUnfollow,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (profiles.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 200),
        Center(
          child: Column(
            children: [
              Icon(Icons.people_outline_rounded, size: 48, color: kTextLight),
              SizedBox(height: 8),
              Text('Not following anyone yet',
                  style: TextStyle(color: kTextLight)),
              Text('Discover people in the Discover tab',
                  style: TextStyle(color: kTextLight, fontSize: 12)),
            ],
          ),
        ),
      ]);
    }
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: profiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ProfileCard(
          profile: profiles[i],
          following: true,
          pending: pending.contains(profiles[i].userId),
          onToggle: () => onUnfollow(profiles[i]),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final PublicProfile profile;
  final bool following;
  final bool pending;
  final VoidCallback onToggle;

  const _ProfileCard({
    required this.profile,
    required this.following,
    required this.pending,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kPrimary.withOpacity(0.15),
              backgroundImage: profile.avatarUrl != null
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? Text(
                      profile.displayName[0].toUpperCase(),
                      style: const TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: kTextDark),
                      ),
                      if (profile.isVerifiedExpert) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            color: kPrimary, size: 14),
                      ],
                    ],
                  ),
                  if (profile.bio != null && profile.bio!.isNotEmpty)
                    Text(
                      profile.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: kTextMid),
                    ),
                  Text(
                    '${profile.followersCount} followers · '
                    '${profile.publicRoutinesCount} routines',
                    style: const TextStyle(fontSize: 11, color: kTextLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: pending ? null : onToggle,
                style: OutlinedButton.styleFrom(
                  foregroundColor: following ? kTextMid : kPrimary,
                  side: BorderSide(color: following ? kDivider : kPrimary),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: pending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kPrimary))
                    : Text(following ? 'Unfollow' : 'Follow',
                        style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
