import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive/core_hive_boxes.dart';
import '../../../../core/storage/hive/hive_service.dart';
import '../../domain/entities/chat_message.dart';

class AgentLocalDataSource {
  static const String _legacyChatHistoryKey = 'chat_history';
  static const String _legacySessionIdKey = 'session_id';

  Future<Box<dynamic>>? _boxFuture;

  Future<Box<dynamic>> get _box {
    return _boxFuture ??= HiveService.openBox<dynamic>(CoreHiveBoxes.agent);
  }

  String _historyKeyFor(String userId) => 'chat_history_$userId';

  String _sessionKeyFor(String userId) => 'session_id_$userId';

  Future<List<ChatMessage>> loadChatHistory({required String userId}) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return const <ChatMessage>[];

    final box = await _box;
    final historyKey = _historyKeyFor(normalized);
    var rawHistory = box.get(historyKey);
    if (rawHistory is! List) {
      await migrateLegacyIfNeeded(userId: normalized);
      rawHistory = box.get(historyKey);
    }
    if (rawHistory is! List) return const <ChatMessage>[];

    return rawHistory
        .map(_messageFromCache)
        .whereType<ChatMessage>()
        .toList(growable: false);
  }

  Future<String?> loadSessionId({required String userId}) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return null;

    final box = await _box;
    final sessionKey = _sessionKeyFor(normalized);
    var value = box.get(sessionKey);
    if (value is! String || value.trim().isEmpty) {
      await migrateLegacyIfNeeded(userId: normalized);
      value = box.get(sessionKey);
    }
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> saveConversation({
    required String userId,
    required List<ChatMessage> chatHistory,
    required String? sessionId,
  }) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;

    final box = await _box;
    await box.put(
      _historyKeyFor(normalized),
      chatHistory.map(_messageToCache).toList(growable: false),
    );

    final normalizedSessionId = sessionId?.trim();
    if (normalizedSessionId == null || normalizedSessionId.isEmpty) {
      await box.delete(_sessionKeyFor(normalized));
      return;
    }

    await box.put(_sessionKeyFor(normalized), normalizedSessionId);
  }

  Future<void> migrateLegacyIfNeeded({required String userId}) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;

    final box = await _box;
    final historyKey = _historyKeyFor(normalized);
    final sessionKey = _sessionKeyFor(normalized);

    final hasScopedHistory = box.containsKey(historyKey);
    final hasScopedSession = box.containsKey(sessionKey);
    if (hasScopedHistory || hasScopedSession) return;

    final legacyHistory = box.get(_legacyChatHistoryKey);
    if (legacyHistory is List && legacyHistory.isNotEmpty) {
      await box.put(historyKey, legacyHistory);
      await box.delete(_legacyChatHistoryKey);
    }

    final legacySession = box.get(_legacySessionIdKey);
    if (legacySession is String && legacySession.trim().isNotEmpty) {
      await box.put(sessionKey, legacySession.trim());
      await box.delete(_legacySessionIdKey);
    }
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
