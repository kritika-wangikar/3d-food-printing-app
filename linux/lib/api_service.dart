import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Configuration
  static const String _backendUrl = "http://10.0.2.2:5000"; // Android emulator
  // static const String _backendUrl = "http://localhost:5000"; // iOS simulator
  static const Duration _timeout = Duration(seconds: 240);

  static Future<Map<String, dynamic>> startChat({
    required String message,
    required Map<String, dynamic> conversationState,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_backendUrl/start-chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": message,
          "conversation_state": conversationState,
        }),
      ).timeout(_timeout);

      return _parseResponse(response);
    } catch (e) {
      throw Exception("Failed to start chat: ${e.toString()}");
    }
  }

  // Meshy API through Flask backend
  static Future<Map<String, dynamic>> generateModel({
    required String prompt,
    String artStyle = "realistic",
    bool shouldRemesh = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_backendUrl/generate-model"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "conversation_state": {
            "final_prompt": prompt,  // Match backend structure
          },
          "art_style": artStyle,
          "should_remesh": shouldRemesh,
        }),
      ).timeout(_timeout);

      final responseData = _parseResponse(response);
      return {
        'model_url': responseData['model_url'],
        'thumbnail_url': responseData['thumbnail_url'],
      };
    } catch (e) {
      throw Exception("Failed to generate model: ${e.toString()}");
    }
  }

  // Helper method to parse responses
  static Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        "HTTP ${response.statusCode}: ${response.body.isNotEmpty ? response.body : 'No response body'}"
      );
    }
    return jsonDecode(response.body);
  }
}