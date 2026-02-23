import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIConfig {
  static String get apiKey {
    final key = dotenv.env['OPENAI_PROXY_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception("API KEY não encontrada no .env");
    }
    return key;
  }

  static String get endpoint {
    final url = dotenv.env['OPENAI_PROXY_ENDPOINT'];
    if (url == null || url.isEmpty) {
      throw Exception("ENDPOINT não encontrado no .env");
    }
    return url;
  }
}