import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'openai_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static String get _nodeBackendUrl {
    final url = dotenv.env['backendURL'];
    if (url == null || url.isEmpty) {
      throw Exception("backendURL não encontrado no arquivo .env");
    }
    return url;
  }

  static const String _model = 'gpt-4o';

  static Map<String, String> _jsonHeaders(String apiKey) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Authorization': 'Bearer $apiKey',
  };

  static Uri _buildUri(String endpoint, String path) {
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
    return base.replace(
      path:
          '${base.path.endsWith('/') ? base.path : '${base.path}/'}$normalizedPath',
    );
  }

  static Future<String> answerWithRag({
    required String question,
    required String faqContext,
    required String vectorStoreId,
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    try {
      final url = Uri.parse('$_nodeBackendUrl/chat');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'message': question,
          'history': chatHistory ?? [],
          'context': faqContext,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['reply'];
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        return errorData['error'] ?? 'Erro desconhecido no servidor.';
      }
    } catch (e) {
      debugPrint('Erro no BackendService: $e');
      return 'Nossos servidores estão ocupados no momento. Tente novamente.';
    }
  }

  static Future<String> sendChat(List<Map<String, dynamic>> messages) async {
    if (messages.isEmpty) return '';

    final lastMessage = messages.last['content'] as String;
    final history = messages.length > 1
        ? messages.sublist(0, messages.length - 1)
        : <Map<String, dynamic>>[];

    return answerWithRag(
      question: lastMessage,
      faqContext: '',
      vectorStoreId: '',
      chatHistory: history,
    );
  }

  static Future<String> ensureVectorStore({
    String? existingId,
    required String name,
  }) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) {
      throw Exception('OpenAI API Key or Endpoint not configured.');
    }

    if (existingId != null && existingId.isNotEmpty) return existingId;

    final url = _buildUri(endpoint, '/vector_stores');
    final res = await http.post(
      url,
      headers: _jsonHeaders(apiKey),
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final id = data['id'] as String?;
      if (id == null || id.isEmpty) {
        throw Exception('Vector store created but id missing.');
      }
      return id;
    }
    throw Exception(
      'Failed to create vector store: ${res.statusCode} - ${res.body}',
    );
  }

  static Future<({String fileId, int bytes})> uploadPdfBytes({
    required Uint8List bytes,
    required String filename,
  }) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) {
      throw Exception('OpenAI API Key or Endpoint not configured.');
    }

    final url = _buildUri(endpoint, '/files');

    final req = http.MultipartRequest('POST', url);
    req.headers['Authorization'] = 'Bearer $apiKey';
    req.fields['purpose'] = 'assistants';
    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final fileId = data['id'] as String?;
      if (fileId == null || fileId.isEmpty) {
        throw Exception('File uploaded but id missing.');
      }
      return (fileId: fileId, bytes: bytes.length);
    }
    throw Exception('Failed to upload file: ${res.statusCode} - ${res.body}');
  }

  static Future<String> addFileToVectorStore({
    required String vectorStoreId,
    required String fileId,
  }) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) {
      throw Exception('OpenAI API Key or Endpoint not configured.');
    }

    final url = _buildUri(endpoint, '/vector_stores/$vectorStoreId/files');
    final res = await http.post(
      url,
      headers: _jsonHeaders(apiKey),
      body: jsonEncode({'file_id': fileId}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final vsfId = data['id'] as String?;
      if (vsfId == null || vsfId.isEmpty) {
        throw Exception('Vector store file created but id missing.');
      }
      return vsfId;
    }
    throw Exception(
      'Failed to index file in vector store: ${res.statusCode} - ${res.body}',
    );
  }

  static Future<List<Map<String, dynamic>>> listVectorStoreFiles({
    required String vectorStoreId,
  }) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) {
      throw Exception('OpenAI API Key or Endpoint not configured.');
    }

    final url = _buildUri(endpoint, '/vector_stores/$vectorStoreId/files');
    final res = await http.get(url, headers: _jsonHeaders(apiKey));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final list = data['data'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      return const [];
    }
    throw Exception(
      'Failed to list vector store files: ${res.statusCode} - ${res.body}',
    );
  }

  static Future<void> deleteVectorStoreFile({
    required String vectorStoreId,
    required String vectorStoreFileId,
  }) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) {
      throw Exception('OpenAI API Key or Endpoint not configured.');
    }

    final url = _buildUri(
      endpoint,
      '/vector_stores/$vectorStoreId/files/$vectorStoreFileId',
    );
    final res = await http.delete(url, headers: _jsonHeaders(apiKey));
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception(
      'Failed to delete vector store file: ${res.statusCode} - ${res.body}',
    );
  }

  static Future<void> deleteFile({required String fileId}) async {
    final apiKey = OpenAIConfig.apiKey;
    final endpoint = OpenAIConfig.endpoint;
    if (apiKey.isEmpty || endpoint.isEmpty) {
      throw Exception('OpenAI API Key or Endpoint not configured.');
    }

    final url = _buildUri(endpoint, '/files/$fileId');
    final res = await http.delete(url, headers: _jsonHeaders(apiKey));
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Failed to delete file: ${res.statusCode} - ${res.body}');
  }
}