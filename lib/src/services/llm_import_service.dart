import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_settings.dart';
import '../models/parsed_roster_entry.dart';

class LlmImportService {
  LlmImportService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<ParsedRosterEntry>> parseRoster({
    required AppSettings settings,
    required String sourceText,
  }) async {
    if (!settings.hasLlmConfig) {
      throw const LlmImportException('LLM 未启用或配置不完整');
    }
    if (sourceText.trim().isEmpty) {
      return const [];
    }

    final endpoint = _chatCompletionsUri(settings.llmBaseUrl);
    final response = await _client.post(
      endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settings.llmApiKey}',
      },
      body: jsonEncode({
        'model': settings.llmModel,
        'temperature': 0,
        'messages': [
          {
            'role': 'system',
            'content':
                '你是花名册导入解析器。只返回 JSON，不要解释。格式为 {"entries":[{"displayName":"姓名","note":"可选备注"}]}。',
          },
          {
            'role': 'user',
            'content': '请把以下内容解析为花名册条目：\n$sourceText',
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LlmImportException('LLM 请求失败：${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw const LlmImportException('LLM 未返回可解析内容');
    }

    return _parseEntriesFromContent(content);
  }

  Uri _chatCompletionsUri(String baseUrl) {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/chat/completions')) {
      return Uri.parse(trimmed);
    }
    if (trimmed.endsWith('/v1')) {
      return Uri.parse('$trimmed/chat/completions');
    }
    return Uri.parse('$trimmed/v1/chat/completions');
  }

  List<ParsedRosterEntry> _parseEntriesFromContent(String content) {
    final normalized = _stripCodeFence(content);
    final dynamic decoded = jsonDecode(normalized);
    final entriesJson = decoded is List
        ? decoded
        : decoded is Map<String, dynamic>
            ? decoded['entries'] as List<dynamic>?
            : null;
    if (entriesJson == null) {
      throw const LlmImportException('LLM 返回 JSON 缺少 entries');
    }

    return entriesJson
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => ParsedRosterEntry.fromJson(item.cast<String, Object?>()))
        .where((entry) => entry.isValid)
        .toList();
  }

  String _stripCodeFence(String content) {
    final trimmed = content.trim();
    final match = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$').firstMatch(
      trimmed,
    );
    return match?.group(1)?.trim() ?? trimmed;
  }
}

class LlmImportException implements Exception {
  const LlmImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
