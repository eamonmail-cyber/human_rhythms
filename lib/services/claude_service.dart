import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  Future<String> _apiKey() async {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await rc.fetchAndActivate();
    return rc.getString('ANTHROPIC_API_KEY');
  }

  Future<String> sendMessage(String message) async {
    final String apiKey;
    try {
      apiKey = await _apiKey();
    } catch (e, st) {
      debugPrint('[ClaudeService] Remote Config fetch error: $e\n$st');
      return 'DEBUG Remote Config error: $e';
    }

    if (apiKey.isEmpty) {
      debugPrint('[ClaudeService] ANTHROPIC_API_KEY is empty in Remote Config');
      return 'BUILD-V2-DEBUG: API key empty - not set in Firebase Remote Config';
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': message},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        return (content.first as Map<String, dynamic>)['text'] as String;
      } else {
        debugPrint('[ClaudeService] HTTP ${response.statusCode}: ${response.body}');
        return 'DEBUG HTTP ${response.statusCode}: ${response.body}';
      }
    } catch (e, st) {
      debugPrint('[ClaudeService] Exception: $e\n$st');
      return 'DEBUG Exception: $e';
    }
  }
}
