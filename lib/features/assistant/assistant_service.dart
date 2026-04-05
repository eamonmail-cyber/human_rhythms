import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AssistantService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';

  Future<String> _apiKey() async {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await rc.fetchAndActivate();
    return rc.getString('ANTHROPIC_API_KEY');
  }

  Future<String> sendMessage(
    List<Map<String, dynamic>> messages,
    Map<String, dynamic> userContext,
  ) async {
    final String apiKey;
    try {
      apiKey = await _apiKey();
    } catch (e, st) {
      debugPrint('[AssistantService] Remote Config fetch error: $e\n$st');
      return 'AI Assistant coming soon.';
    }

    if (apiKey.isEmpty) return 'DEBUG: API key empty from Remote Config';

    final systemPrompt = _buildSystemPrompt(userContext);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 500,
          'system': systemPrompt,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        return (content.first as Map<String, dynamic>)['text'] as String;
      }
      return 'DEBUG HTTP ${response.statusCode}: ${response.body}';
    } catch (e) {
      return 'DEBUG Exception: $e';
    }
  }

  String _buildSystemPrompt(Map<String, dynamic> ctx) => '''
You are a personal wellness assistant inside the Human Rhythms app.
Help users understand their routines, discover new ones, and interpret
their health data. Always be warm and encouraging, never judgemental.
Speak conversationally in plain English. Keep responses to 2-3 short
paragraphs maximum. Be specific — reference their actual data.

The user currently has these active routines: ${ctx['routineList'] ?? 'none yet'}
Their mood average this week: ${ctx['mood'] ?? 'not logged'}/10
Their energy average this week: ${ctx['energy'] ?? 'not logged'}/10
Their current streak: ${ctx['streak'] ?? 0} days
Member for: ${ctx['weeks'] ?? 0} weeks

If they ask to search for routines suggest categories from the
community library. If they ask about their data reference the
numbers above specifically. Always end with one clear actionable
suggestion they can do today.''';
}
