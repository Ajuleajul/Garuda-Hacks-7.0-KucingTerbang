import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    required this.at,
  });

  final String role;
  final String content;
  final DateTime at;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'at': at.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: (json['role'] ?? 'assistant').toString(),
      content: (json['content'] ?? '').toString(),
      at: DateTime.tryParse((json['at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, String> toApi() => {
        'role': role == 'user' ? 'user' : 'model',
        'content': content,
      };
}

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  Future<String> send({
    required List<ChatMessage> history,
    required String userMessage,
  }) async {
    final patientId = AuthService.instance.currentUser?.id;
    final messages = <Map<String, String>>[
      for (final m in history)
        if (m.content.trim().isNotEmpty) m.toApi(),
      {'role': 'user', 'content': userMessage},
    ];

    final res = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            if (patientId != null && patientId.isNotEmpty)
              'patient_id': patientId,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 45));

    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final err = (body['error'] ?? 'Chat request failed (${res.statusCode}).')
          .toString();
      throw ChatFailure(err);
    }

    final reply = (body['reply'] ?? body['message'] ?? '').toString().trim();
    if (reply.isEmpty) {
      throw const ChatFailure('Empty reply from Curamind assistant.');
    }
    return reply;
  }
}

class ChatFailure implements Exception {
  const ChatFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
