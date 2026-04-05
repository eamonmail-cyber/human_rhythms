import 'package:flutter/material.dart';
import '../theme.dart';

/// Reusable anonymous posting toggle row used across Stories, Groups,
/// and Challenges share flows.
class AnonymousToggle extends StatelessWidget {
  final bool isAnonymous;
  final ValueChanged<bool> onChanged;
  final String? namedLabel;

  const AnonymousToggle({
    super.key,
    required this.isAnonymous,
    required this.onChanged,
    this.namedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isAnonymous),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAnonymous
              ? kPrimary.withOpacity(0.08)
              : kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAnonymous ? kPrimary.withOpacity(0.3) : kDivider,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isAnonymous
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                key: ValueKey(isAnonymous),
                size: 18,
                color: isAnonymous ? kPrimary : kTextLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAnonymous ? 'Posting anonymously' : 'Posting as yourself',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isAnonymous ? kPrimary : kTextDark,
                    ),
                  ),
                  Text(
                    isAnonymous
                        ? 'Others see only your alias and age range.'
                        : (namedLabel ??
                            'Your name and profile will be visible.'),
                    style: const TextStyle(fontSize: 11, color: kTextLight),
                  ),
                ],
              ),
            ),
            Switch(
              value: isAnonymous,
              activeColor: kPrimary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a preview of how the post looks before publishing.
/// [namedPreview] and [anonymousPreview] are builder callbacks returning
/// the preview widget for each mode.
class AnonymousPreviewSheet extends StatefulWidget {
  final String title;
  final bool initialIsAnonymous;
  final Widget Function(bool isAnonymous) previewBuilder;
  final Future<void> Function(bool isAnonymous) onPost;
  final String? namedLabel;

  const AnonymousPreviewSheet({
    super.key,
    required this.title,
    required this.initialIsAnonymous,
    required this.previewBuilder,
    required this.onPost,
    this.namedLabel,
  });

  @override
  State<AnonymousPreviewSheet> createState() =>
      _AnonymousPreviewSheetState();
}

class _AnonymousPreviewSheetState extends State<AnonymousPreviewSheet> {
  late bool _isAnonymous;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _isAnonymous = widget.initialIsAnonymous;
  }

  Future<void> _post() async {
    setState(() => _posting = true);
    try {
      await widget.onPost(_isAnonymous);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _posting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post. Please try again.')),
        );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.title,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Preview how your post will appear:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: kTextLight)),
          const SizedBox(height: 16),

          // Live preview
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_isAnonymous),
              child: widget.previewBuilder(_isAnonymous),
            ),
          ),

          const SizedBox(height: 16),

          // Anonymous toggle
          AnonymousToggle(
            isAnonymous: _isAnonymous,
            onChanged: (v) => setState(() => _isAnonymous = v),
            namedLabel: widget.namedLabel,
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _posting ? null : _post,
              child: _posting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}
