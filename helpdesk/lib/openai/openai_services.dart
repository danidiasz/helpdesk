import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'openai_config.dart';

class OpenAIService {
  static const String _model = 'gpt-4o';

  static Map<String, String> _jsonHeaders(String apiKey) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Authorization': 'Bearer $apiKey',
  };

  /// Dreamflow's proxy env typically provides an endpoint that is *already* a full OpenAI path
  /// (often /v1/chat/completions). We need a robust base for other endpoints (files, vector stores, responses).
  static Uri _buildUri(String endpoint, String path) {
    // If endpoint already ends with a known OpenAI path, derive base up to `/v1`.
    final uri = Uri.parse(endpoint);
    final segments = uri.pathSegments;
    final v1Index = segments.indexOf('v1');
    Uri base;
    if (v1Index != -1) {
      final baseSegments = segments.sublist(0, v1Index + 1);
      base = uri.replace(pathSegments: baseSegments);
    } else {
      base = uri;
    }
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return base.replace(path: '${base.path.endsWith('/') ? base.path : '${base.path}/'}$normalizedPath');
  }

  static Future<String> sendChat(List<Map<String, dynamic>> messages) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;

    if (apiKey.isEmpty || endpoint.isEmpty) {
      throw Exception('OpenAI API Key or Endpoint not configured.');
    }

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: _jsonHeaders(apiKey),
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending chat: $e');
    }
  }

  static Future<String> ensureVectorStore({String? existingId, required String name}) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) throw Exception('OpenAI API Key or Endpoint not configured.');

    if (existingId != null && existingId.isNotEmpty) return existingId;

    final url = _buildUri(endpoint, '/vector_stores');
    final res = await http.post(url, headers: _jsonHeaders(apiKey), body: jsonEncode({'name': name}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final id = data['id'] as String?;
      if (id == null || id.isEmpty) throw Exception('Vector store created but id missing.');
      return id;
    }
    throw Exception('Failed to create vector store: ${res.statusCode} - ${res.body}');
  }

  static Future<({String fileId, int bytes})> uploadPdfBytes({required Uint8List bytes, required String filename}) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) throw Exception('OpenAI API Key or Endpoint not configured.');

    final url = _buildUri(endpoint, '/files');

    final req = http.MultipartRequest('POST', url);
    req.headers['Authorization'] = 'Bearer $apiKey';
    req.fields['purpose'] = 'assistants';
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final fileId = data['id'] as String?;
      if (fileId == null || fileId.isEmpty) throw Exception('File uploaded but id missing.');
      return (fileId: fileId, bytes: bytes.length);
    }
    throw Exception('Failed to upload file: ${res.statusCode} - ${res.body}');
  }

  static Future<String> addFileToVectorStore({required String vectorStoreId, required String fileId}) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) throw Exception('OpenAI API Key or Endpoint not configured.');

    final url = _buildUri(endpoint, '/vector_stores/$vectorStoreId/files');
    final res = await http.post(url, headers: _jsonHeaders(apiKey), body: jsonEncode({'file_id': fileId}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final vsfId = data['id'] as String?;
      if (vsfId == null || vsfId.isEmpty) throw Exception('Vector store file created but id missing.');
      return vsfId;
    }
    throw Exception('Failed to index file in vector store: ${res.statusCode} - ${res.body}');
  }

  static Future<List<Map<String, dynamic>>> listVectorStoreFiles({required String vectorStoreId}) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) throw Exception('OpenAI API Key or Endpoint not configured.');

    final url = _buildUri(endpoint, '/vector_stores/$vectorStoreId/files');
    final res = await http.get(url, headers: _jsonHeaders(apiKey));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final list = data['data'];
      if (list is List) return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      return const [];
    }
    throw Exception('Failed to list vector store files: ${res.statusCode} - ${res.body}');
  }

  static Future<void> deleteVectorStoreFile({required String vectorStoreId, required String vectorStoreFileId}) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) throw Exception('OpenAI API Key or Endpoint not configured.');

    final url = _buildUri(endpoint, '/vector_stores/$vectorStoreId/files/$vectorStoreFileId');
    final res = await http.delete(url, headers: _jsonHeaders(apiKey));
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Failed to delete vector store file: ${res.statusCode} - ${res.body}');
  }

  static Future<void> deleteFile({required String fileId}) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) throw Exception('OpenAI API Key or Endpoint not configured.');

    final url = _buildUri(endpoint, '/files/$fileId');
    final res = await http.delete(url, headers: _jsonHeaders(apiKey));
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Failed to delete file: ${res.statusCode} - ${res.body}');
  }

  static Future<String> answerWithRag({
    required String question,
    required String faqContext,
    required String vectorStoreId,
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) throw Exception('OpenAI API Key or Endpoint not configured.');

    final url = _buildUri(endpoint, '/responses');

    final instructions = """
Você é um assistente interno.

Regras obrigatórias:
1) Responda usando APENAS as informações do FAQ e do conteúdo recuperado dos PDFs.
2) Se não houver informação suficiente, diga exatamente: "Não encontrei essa informação na base enviada (FAQ/PDF)."
3) Responda em português.

FAQ (fonte primária):
$faqContext
""";

    final input = <Map<String, dynamic>>[
      {'role': 'system', 'content': instructions},
      ...?chatHistory,
      {'role': 'user', 'content': question},
    ];

    final body = {
      'model': _model,
      'input': input,
      'tools': [
        {
          'type': 'file_search',
          'vector_store_ids': [vectorStoreId],
        }
      ],
      'max_output_tokens': 900,
    };

    final res = await http.post(url, headers: _jsonHeaders(apiKey), body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      // Responses API can return `output_text` directly in newer versions.
      final outputText = data['output_text'];
      if (outputText is String && outputText.isNotEmpty) return outputText;

      // Fallback: traverse output blocks.
      final output = data['output'];
      if (output is List) {
        final buffer = StringBuffer();
        for (final item in output) {
          if (item is Map && item['content'] is List) {
            for (final c in (item['content'] as List)) {
              if (c is Map && c['type'] == 'output_text' && c['text'] is String) buffer.writeln(c['text']);
            }
          }
        }
        final text = buffer.toString().trim();
        if (text.isNotEmpty) return text;
      }
      debugPrint('Unexpected responses payload: $data');
      return 'Não consegui interpretar a resposta do modelo.';
    }
    throw Exception('Failed to get RAG response: ${res.statusCode} - ${res.body}');
  }
}