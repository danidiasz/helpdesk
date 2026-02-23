import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static String get _baseUrl {
    final url = dotenv.env['backendURL'];
    if (url == null || url.isEmpty) {
      throw Exception("backendURL não encontrado no .env");
    }
    return url;
  }

  static Future<String> answerWithRag({
    required String question,
    required String faqContext,
    required String vectorStoreId,
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'message': question,
              'history': chatHistory ?? [],
              'context': faqContext,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['reply'];
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        return errorData['error'] ?? 'Erro no servidor.';
      }
    } catch (e) {
      return 'Erro de conexão com o servidor de IA.';
    }
  }

  static Future<String> ensureVectorStore({
    String? existingId,
    required String name,
  }) async {
    if (existingId != null && existingId.isNotEmpty) return existingId;

    final res = await http.post(
      Uri.parse('$_baseUrl/files/vector-stores'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['vectorStoreId'];
    }
    throw Exception('Falha ao criar Vector Store no servidor.');
  }

  static Future<({String fileId, int bytes})> uploadPdfBytes({
    required Uint8List bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/files/upload'),
    );

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (fileId: data['fileId'] as String, bytes: bytes.length);
    }
    throw Exception('Falha no upload do arquivo.');
  }

  static Future<String> addFileToVectorStore({
    required String vectorStoreId,
    required String fileId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/files/vector-stores/attach'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'vectorStoreId': vectorStoreId, 'fileId': fileId}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['vectorStoreFileId'];
    }
    throw Exception('Falha ao indexar arquivo.');
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

  static Future<List<Map<String, dynamic>>> listVectorStoreFiles({
    required String vectorStoreId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/files/vector-stores/$vectorStoreId/files'),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception('Falha ao listar arquivos.');
  }

  static Future<void> deleteVectorStoreFile({
    required String vectorStoreId,
    required String vectorStoreFileId,
  }) async {
    await http.delete(
      Uri.parse(
        '$_baseUrl/files/vector-stores/$vectorStoreId/files/$vectorStoreFileId',
      ),
    );
  }

  static Future<void> deleteFile({required String fileId}) async {
    await http.delete(Uri.parse('$_baseUrl/files/$fileId'));
  }
}