// lib/services/claude_service.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// A single message in a Claude conversation.
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Thrown when the Claude API returns an error or is unreachable.
class ClaudeException implements Exception {
  final String message;
  const ClaudeException(this.message);

  @override
  String toString() => 'ClaudeException: $message';
}

/// Service that wraps the Anthropic Messages API.
///
/// The API key is read from the `ANTHROPIC_API_KEY` dart-define at build time:
///   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
///
/// For CI (Codemagic), store ANTHROPIC_API_KEY in the 'anthropic' env group
/// and pass it via --dart-define in the build script (see codemagic.yaml).
class ClaudeService {
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';
  static const _maxTokens = 1024;
  static const _systemPrompt =
      'You are a warm, supportive wellness coach inside the Human Rhythms app. '
      'Help users reflect on their mood, routines, and daily diary entries. '
      'Keep responses concise (2–4 sentences) and encouraging. '
      'Never provide medical advice.';

  final http.Client _client;

  ClaudeService({http.Client? client}) : _client = client ?? http.Client();

  /// Send [messages] to Claude and return the assistant reply text.
  ///
  /// [messages] should be the full conversation history so far, oldest first,
  /// alternating user / assistant roles.
  Future<String> chat(List<ChatMessage> messages) async {
    if (_apiKey.isEmpty) {
      throw const ClaudeException(
        'API key not configured. '
        'Rebuild with --dart-define=ANTHROPIC_API_KEY=<your-key>.',
      );
    }

    final body = jsonEncode({
      'model': _model,
      'max_tokens': _maxTokens,
      'system': _systemPrompt,
      'messages': messages.map((m) => m.toJson()).toList(),
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } on Exception catch (e) {
      throw ClaudeException('Network error: $e');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final contentList = decoded['content'] as List<dynamic>;
      if (contentList.isEmpty) {
        throw const ClaudeException('Empty response from Claude.');
      }
      final firstBlock = contentList.first as Map<String, dynamic>;
      return (firstBlock['text'] as String).trim();
    }

    // Surface API error messages to the caller.
    String apiError = 'Status ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final errorObj = decoded['error'] as Map<String, dynamic>?;
      if (errorObj != null) {
        apiError = errorObj['message'] as String? ?? apiError;
      }
    } catch (_) {}
    throw ClaudeException(apiError);
  }

  void dispose() => _client.close();
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// Singleton ClaudeService scoped to the app lifetime.
final claudeServiceProvider = Provider<ClaudeService>((ref) {
  final service = ClaudeService();
  ref.onDispose(service.dispose);
  return service;
});

/// State for one conversation thread: an ordered list of [ChatMessage]s.
final conversationProvider =
    StateNotifierProvider<ConversationNotifier, List<ChatMessage>>(
  (ref) => ConversationNotifier(),
);

class ConversationNotifier extends StateNotifier<List<ChatMessage>> {
  ConversationNotifier() : super(const []);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clear() {
    state = const [];
  }
}

/// AsyncNotifier that sends a user message and appends the assistant reply.
final chatNotifierProvider =
    AsyncNotifierProvider<ChatNotifier, void>(ChatNotifier.new);

class ChatNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Send [userText] and update the conversation state with the reply.
  Future<void> sendMessage(String userText) async {
    final service = ref.read(claudeServiceProvider);
    final conversation = ref.read(conversationProvider.notifier);

    final userMsg = ChatMessage(role: 'user', content: userText);
    conversation.addMessage(userMsg);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final history = ref.read(conversationProvider);
      final reply = await service.chat(history);
      conversation.addMessage(ChatMessage(role: 'assistant', content: reply));
    });
  }
}
