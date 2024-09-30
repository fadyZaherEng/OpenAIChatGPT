import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:open_ai_gpt/constants.dart';

class APIService {
  Future<http.Response> requestOpenAI(
      String userInput, String mode, int maximumTokens) async {
    const String url = "https://api.openai.com/";
    final String openAiApiUrl =
        mode == "chat" ? "v1/completions" : "v1/images/generations";

    final body = mode == "chat"
        ? {
            "model": "gpt-3.5-turbo-instruct",
            "prompt": userInput,
            "max_tokens": 7,
            "temperature": 0,
          }
        : {
            "prompt": userInput,
          };

    final responseFromOpenAPI = await http.post(
      Uri.parse(url + openAiApiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${ApiKeys.openAiApiKey}"
      },
      body: jsonEncode(body),
    );

    return responseFromOpenAPI;
  }
}
