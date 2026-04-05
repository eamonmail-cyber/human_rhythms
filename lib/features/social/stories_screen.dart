import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/anonymous_toggle.dart';
import '../../data/models/social_models.dart';
import '../../providers/global.dart';

class StoriesScreen extends ConsumerStatefulWidget {
  const StoriesScreen({super.key});

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
  List<RoutineStory> _stories = [];
  bool _loading = true;
  final Set<String> _likedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ref.read(libraryRepoProvider).getStories();
    if (mounted) setState(() { _stories = items; _loading = false; });
  }

  Future<void> _like(String id) async {
    if (_likedIds.contains(id)) return;
    setState(() => _likedIds.add(id));
    await ref.read(libraryRepoProvider).likeStory(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Success Stories',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _load,
              child: _stories.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text('No stories yet',
                            style: TextStyle(color: kTextLight)),
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _stories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => _StoryCard(
                        story: _stories[i],
                        liked: _likedIds.contains(_stories[i].id),
                        onLike: () => _like(_stories[i].id),
                        onToggleAnonymous: (anon) =>
                            _toggleAnonymous(_stories[i], anon),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Share Story',
            style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _showShareSheet,
      ),
    );
  }

  Future<void> _toggleAnonymous(RoutineStory story, bool anon) async {
    try {
      final updated = story.withAnonymous(anon);
      await ref.read(libraryRepoProvider).publishStory(updated);
      _load();
    } catch (_) {}
  }

  void _showShareSheet() {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareStorySheet(
        userId: userId,
        onShared: _load,
      ),
    );
  }
}

// ── Story card ────────────────────────────────────────────────────────────────

class _StoryCard extends ConsumerWidget {
  final RoutineStory story;
  final bool liked;
  final VoidCallback onLike;
  final ValueChanged<bool> onToggleAnonymous;

  const _StoryCard({
    required this.story,
    required this.liked,
    required this.onLike,
    required this.onToggleAnonymous,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(userIdProvider);
    final isOwner = currentUserId == story.authorId;

    return Card(
      color: kCard,
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: kPrimary.withOpacity(0.15),
                  backgroundImage:
                      story.authorAvatarUrl != null && !story.isAnonymous
                          ? NetworkImage(story.authorAvatarUrl!)
                          : null,
                  child:
                      story.authorAvatarUrl == null || story.isAnonymous
                          ? Text(
                              story.authorName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          story.isAnonymous
                              ? 'Anonymous'
                              : story.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: kTextDark),
                        ),
                        if (story.isAnonymous) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.visibility_off_outlined,
                              size: 12, color: kTextLight),
                        ],
                      ],
                    ),
                    Text(
                      'Age ${story.authorAge > 0 ? story.authorAge : "unknown"} · ${story.durationWeeks}w journey',
                      style:
                          const TextStyle(fontSize: 11, color: kTextLight),
                    ),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(story.routineTitle,
                      style: const TextStyle(
                          fontSize: 10, color: kPrimary)),
                  backgroundColor: kPrimary.withOpacity(0.08),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              story.title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextDark),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _BeforeAfterBox(
                        label: 'Before',
                        text: story.beforeDescription,
                        color: kAccent)),
                const SizedBox(width: 8),
                Expanded(
                    child: _BeforeAfterBox(
                        label: 'After',
                        text: story.afterDescription,
                        color: kPrimary)),
              ],
            ),
            if (story.improvements.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: story.improvements
                    .map((imp) => Chip(
                          label: Text(imp,
                              style: const TextStyle(
                                  fontSize: 10, color: kTextMid)),
                          backgroundColor: kSurface,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: liked ? kAccent : kTextLight,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${story.likesCount + (liked ? 1 : 0)}',
                          style: const TextStyle(
                              color: kTextLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Owner can toggle anonymous on their own stories
                if (isOwner)
                  GestureDetector(
                    onTap: () =>
                        onToggleAnonymous(!story.isAnonymous),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: story.isAnonymous
                            ? kPrimary.withOpacity(0.1)
                            : kSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: story.isAnonymous
                                ? kPrimary.withOpacity(0.3)
                                : kDivider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            story.isAnonymous
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 12,
                            color: story.isAnonymous
                                ? kPrimary
                                : kTextLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            story.isAnonymous ? 'Anonymous' : 'Named',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: story.isAnonymous
                                    ? kPrimary
                                    : kTextLight),
                          ),
                        ],
                      ),
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

class _BeforeAfterBox extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _BeforeAfterBox(
      {required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, color: kTextDark)),
          ],
        ),
      );
}

// ── Share story sheet ─────────────────────────────────────────────────────────

class _ShareStorySheet extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onShared;
  const _ShareStorySheet(
      {required this.userId, required this.onShared});
  @override
  ConsumerState<_ShareStorySheet> createState() =>
      _ShareStorySheetState();
}

class _ShareStorySheetState extends ConsumerState<_ShareStorySheet> {
  final _titleCtrl = TextEditingController();
  final _beforeCtrl = TextEditingController();
  final _afterCtrl = TextEditingController();
  final _routineCtrl = TextEditingController();
  int _weeks = 4;
  bool _isAnonymous = false;
  bool _showPreview = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _beforeCtrl.dispose();
    _afterCtrl.dispose();
    _routineCtrl.dispose();
    super.dispose();
  }

  RoutineStory _buildStory(bool anon) => RoutineStory(
    id: '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}',
    authorId: widget.userId,
    authorName: 'You',
    authorAge: 0,
    title: _titleCtrl.text.trim(),
    beforeDescription: _beforeCtrl.text.trim(),
    afterDescription: _afterCtrl.text.trim(),
    routineId: widget.userId,
    routineTitle: _routineCtrl.text.trim().isEmpty
        ? 'Personal Routine'
        : _routineCtrl.text.trim(),
    durationWeeks: _weeks,
    isAnonymous: anon,
    createdAt: DateTime.now(),
  );

  void _goToPreview() {
    final t = _titleCtrl.text.trim();
    final b = _beforeCtrl.text.trim();
    final a = _afterCtrl.text.trim();
    if (t.isEmpty || b.isEmpty || a.isEmpty) {
      setState(
          () => _error = 'Please fill in title, before and after.');
      return;
    }
    setState(() { _error = null; _showPreview = true; });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: _showPreview ? _buildPreviewStep() : _buildFormStep(),
      ),
    );
  }

  Widget _buildFormStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: kDivider,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Share Your Story',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
              labelText: 'Story title', hintText: 'e.g. How sleep changed everything'),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _routineCtrl,
          decoration: const InputDecoration(
              labelText: 'Routine name (optional)'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _beforeCtrl,
          decoration: const InputDecoration(labelText: 'Before'),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          maxLength: 200,
        ),
        TextField(
          controller: _afterCtrl,
          decoration: const InputDecoration(labelText: 'After'),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          maxLength: 200,
        ),
        // Weeks
        Row(
          children: [
            Text('Duration:',
                style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            ...([1, 2, 4, 8, 12].map((w) {
              final sel = w == _weeks;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _weeks = w),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? kPrimary : kSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? kPrimary : kDivider),
                    ),
                    child: Text('${w}w',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : kTextMid)),
                  ),
                ),
              );
            })),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: const TextStyle(color: kAccent, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _goToPreview,
            child: const Text('Preview & Post'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: kDivider,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showPreview = false),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: kTextMid),
            ),
            const SizedBox(width: 10),
            Text('Preview',
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),

        // Live preview of story card header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: kPrimary.withOpacity(0.15),
                    child: Text(
                      _isAnonymous ? 'A' : 'Y',
                      style: const TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAnonymous ? 'Anonymous' : 'You',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: kTextDark),
                      ),
                      Text(
                        '${_weeks}w journey',
                        style: const TextStyle(
                            fontSize: 11, color: kTextLight),
                      ),
                    ],
                  ),
                  if (_isAnonymous) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_off_outlined,
                              size: 10, color: kPrimary),
                          SizedBox(width: 3),
                          Text('Anon',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimary)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(_titleCtrl.text.trim(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: kTextDark)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kAccent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Before',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: kAccent,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(_beforeCtrl.text.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: kTextDark)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('After',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(_afterCtrl.text.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: kTextDark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Anonymous toggle
        AnonymousToggle(
          isAnonymous: _isAnonymous,
          onChanged: (v) => setState(() => _isAnonymous = v),
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _post,
            child: const Text('Share Story'),
          ),
        ),
      ],
    );
  }

  Future<void> _post() async {
    final story = _buildStory(_isAnonymous);
    try {
      await ref.read(libraryRepoProvider).publishStory(story);
      widget.onShared();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to share story.')));
      }
    }
  }
}
