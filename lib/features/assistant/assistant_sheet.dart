import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/theme.dart';
import '../../data/models/entry.dart';
import '../../data/models/enums.dart';
import '../../data/models/outcome.dart';
import '../../data/models/routine.dart';
import '../../data/services/firebase_service.dart';
import '../auth/sign_in_screen.dart';
import 'assistant_service.dart';

class AssistantSheet extends StatefulWidget {
  final String? userId;
  const AssistantSheet({super.key, this.userId});

  @override
  State<AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<AssistantSheet> {
  final _service = AssistantService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _speech = SpeechToText();

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  Map<String, dynamic>? _userContext;

  static const _suggestions = [
    'What should I work on?',
    'Find me a routine for better sleep',
    'How am I doing this week?',
    'What has improved lately?',
    'I only have 15 minutes each morning',
    'Why is my energy low?',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.userId != null) _loadContext(widget.userId!);
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (s) {
        if (mounted) setState(() => _isListening = s == 'listening');
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadContext(String userId) async {
    try {
      final now = DateTime.now();
      final since7 = _ds(now.subtract(const Duration(days: 7)));
      final today = _ds(now);

      final routineSnap = await Fb.col('routines')
          .where('userId', isEqualTo: userId)
          .where('active', isEqualTo: true)
          .get();
      final routines = routineSnap.docs
          .map((d) => Routine.fromMap(d.id, d.data()))
          .toList();

      final outcomeSnap = await Fb.col('outcomes')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: since7)
          .where('date', isLessThanOrEqualTo: today)
          .get();
      final outcomes = outcomeSnap.docs
          .map((d) => Outcome.fromMap(d.id, d.data()))
          .toList();

      final entrySnap = await Fb.col('entries')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: since7)
          .where('date', isLessThanOrEqualTo: today)
          .get();
      final entries = entrySnap.docs
          .map((d) => Entry.fromMap(d.id, d.data()))
          .toList();

      // Compute averages
      final moodVals = outcomes
          .where((o) => o.mood != null)
          .map((o) => o.mood!.toDouble())
          .toList();
      final energyVals = outcomes
          .where((o) => o.energy != null)
          .map((o) => o.energy!.toDouble())
          .toList();

      final avgMood = moodVals.isEmpty
          ? null
          : (moodVals.reduce((a, b) => a + b) / moodVals.length)
              .toStringAsFixed(1);
      final avgEnergy = energyVals.isEmpty
          ? null
          : (energyVals.reduce((a, b) => a + b) / energyVals.length)
              .toStringAsFixed(1);

      // Streak
      var streak = 0;
      for (var i = 0; i < 60; i++) {
        final ds = _ds(now.subtract(Duration(days: i)));
        if (entries.any(
            (e) => e.date == ds && e.status == EntryStatus.done)) {
          streak++;
        } else {
          break;
        }
      }

      // Weeks since first routine created
      int weeks = 0;
      if (routines.isNotEmpty) {
        final earliest = routines
            .map((r) => r.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        weeks = now.difference(earliest).inDays ~/ 7;
      }

      if (mounted) {
        setState(() {
          _userContext = {
            'routineList': routines.map((r) => r.title).join(', '),
            'mood': avgMood,
            'energy': avgEnergy,
            'streak': streak,
            'weeks': weeks,
          };
        });
      }
    } catch (_) {
      // context load failure is non-fatal
    }
  }

  String _ds(DateTime d) =>
      '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: trimmed));
      _isLoading = true;
    });
    _scrollToBottom();

    final history = _messages
        .where((m) => m.role != 'loading')
        .map((m) => {'role': m.role, 'content': m.text})
        .toList();

    final reply = await _service.sendMessage(
      history,
      _userContext ?? {},
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(role: 'assistant', text: reply));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else if (_speechAvailable) {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _controller.text = result.recognizedWords;
              if (result.finalResult) _isListening = false;
            });
          }
        },
      );
      setState(() => _isListening = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: kDivider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      color: kPrimary, shape: BoxShape.circle),
                  child: Center(child: HRLogo(size: 20, light: true)),
                ),
                const SizedBox(width: 12),
                Text('Your Wellness Assistant',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: kTextMid,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Message list
          Expanded(
            child: _messages.isEmpty
                ? _buildSuggestions()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_isLoading && i == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _TypingIndicator(),
                          ),
                        );
                      }
                      return _buildBubble(_messages[i]);
                    },
                  ),
          ),
          // Input row
          Container(
            decoration: const BoxDecoration(
              color: kCard,
              border: Border(top: BorderSide(color: kDivider)),
            ),
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: kTextDark),
                        decoration: InputDecoration(
                          hintText: 'Ask anything...',
                          hintStyle: const TextStyle(color: kTextLight),
                          filled: true,
                          fillColor: kSurface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: _send,
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_speechAvailable)
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: _isListening ? kAccent : kTextMid,
                        ),
                        onPressed: _toggleListening,
                      ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: kPrimary,
                      onPressed: () => _send(_controller.text),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Responses generated privately and not stored',
                  style: TextStyle(fontSize: 10, color: kTextLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What would you like to explore?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: kTextMid)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => ActionChip(
                      label: Text(s,
                          style: const TextStyle(
                              fontSize: 13, color: kTextDark)),
                      backgroundColor: kCard,
                      side: const BorderSide(color: kDivider),
                      onPressed: () => _send(s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? kPrimary : kCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? Colors.white : kTextDark,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ── Chat message model ────────────────────────────────────────────────────────

class _ChatMessage {
  final String role;
  final String text;
  const _ChatMessage({required this.role, required this.text});
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_anim.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2))
                .clamp(0.3, 1.0);
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }
}
