import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive/core_hive_boxes.dart';
import '../../../../core/storage/hive/hive_service.dart';
import '../../domain/entities/chat_message.dart';

class AgentLocalDataSource {
  static const String _chatHistoryKey = 'chat_history';
  static const String _sessionIdKey = 'session_id';

  Future<Box<dynamic>>? _boxFuture;

  Future<Box<dynamic>> get _box {
    return _boxFuture ??= HiveService.openBox<dynamic>(CoreHiveBoxes.agent);
  }

  Future<List<ChatMessage>> loadChatHistory() async {
    final box = await _box;
    final rawHistory = box.get(_chatHistoryKey);
    if (rawHistory is! List) return const <ChatMessage>[];

    return rawHistory
        .map(_messageFromCache)
        .whereType<ChatMessage>()
        .toList(growable: false);
  }

  Future<String?> loadSessionId() async {
    final box = await _box;
    final value = box.get(_sessionIdKey);
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> saveConversation({
    required List<ChatMessage> chatHistory,
    required String? sessionId,
  }) async {
    final box = await _box;
    await box.put(
      _chatHistoryKey,
      chatHistory.map(_messageToCache).toList(growable: false),
    );

    final normalizedSessionId = sessionId?.trim();
    if (normalizedSessionId == null || normalizedSessionId.isEmpty) {
      await box.delete(_sessionIdKey);
      return;
    }

    await box.put(_sessionIdKey, normalizedSessionId);
  }

  Map<String, dynamic> _messageToCache(ChatMessage message) {
    return <String, dynamic>{
      'text': message.text,
      'is_user': message.isUser,
      'timestamp': message.timestamp.toIso8601String(),
    };
  }

  ChatMessage? _messageFromCache(dynamic value) {
    if (value is! Map) return null;

    final text = value['text'];
    final isUser = value['is_user'];
    final timestamp = value['timestamp'];

    if (text is! String || isUser is! bool) return null;

    return ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: timestamp is String
          ? DateTime.tryParse(timestamp) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
