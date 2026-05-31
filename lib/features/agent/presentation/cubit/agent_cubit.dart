import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/location_service.dart';
import '../../data/local/agent_local_data_source.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/agent_repository.dart';
import 'agent_state.dart';

class AgentCubit extends Cubit<AgentState> {
  final AgentRepository _repository;
  final LocationService _locationService;
  final AgentLocalDataSource _localDataSource;
  late final Future<void> _restoreFuture;

  AgentCubit({
    required AgentRepository repository,
    required LocationService locationService,
    required AgentLocalDataSource localDataSource,
  }) : _repository = repository,
       _locationService = locationService,
       _localDataSource = localDataSource,
       super(AgentState.initial()) {
    _restoreFuture = _restoreConversation();
  }

  Future<void> sendMessage(String text) async {
    await _restoreFuture;

    final userText = text.trim();
    if (userText.isEmpty || state.status == AgentStatus.loading) return;

    final userMessage = ChatMessage(
      text: userText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final historyWithUserMessage = List<ChatMessage>.unmodifiable([
      ...state.chatHistory,
      userMessage,
    ]);

    emit(
      state.copyWith(
        chatHistory: historyWithUserMessage,
        status: AgentStatus.loading,
        clearError: true,
      ),
    );
    await _persistConversation(
      chatHistory: historyWithUserMessage,
      sessionId: state.currentSessionId,
    );

    final backendQuery = await _buildLocationAwareQuery(userText);
    if (backendQuery == null) {
      // Rollback the user message on location failure.
      final rolledBackHistory = List<ChatMessage>.unmodifiable(
        state.chatHistory.length > 1
            ? state.chatHistory.sublist(0, state.chatHistory.length - 1)
            : state.chatHistory,
      );
      await _persistConversation(
        chatHistory: rolledBackHistory,
        sessionId: state.currentSessionId,
      );
      emit(
        state.copyWith(
          chatHistory: rolledBackHistory,
          status: AgentStatus.locationError,
          errorMessage: AppStrings.agentLocationError,
        ),
      );
      return;
    }

    final result = await _repository.sendQuery(
      userQuery: backendQuery,
      sessionId: state.currentSessionId,
    );

    await result.when(
      success: (reply) async {
        final nextSessionId = reply.sessionId.trim().isEmpty
            ? state.currentSessionId
            : reply.sessionId.trim();
        final agentMessage = ChatMessage(
          text: reply.answer.trim().isEmpty
              ? AppStrings.agentFallbackAnswer
              : reply.answer.trim(),
          isUser: false,
          timestamp: DateTime.now(),
        );
        final historyWithAgentMessage = List<ChatMessage>.unmodifiable([
          ...state.chatHistory,
          agentMessage,
        ]);

        emit(
          state.copyWith(
            chatHistory: historyWithAgentMessage,
            status: AgentStatus.success,
            currentSessionId: nextSessionId,
            clearError: true,
          ),
        );
        await _persistConversation(
          chatHistory: historyWithAgentMessage,
          sessionId: nextSessionId,
        );
      },
      failure: (error) async {
        // Rollback the user message on failure so it vanishes from the chat.
        final rolledBackHistory = List<ChatMessage>.unmodifiable(
          state.chatHistory.length > 1
              ? state.chatHistory.sublist(0, state.chatHistory.length - 1)
              : state.chatHistory,
        );

        // Sync the rolled-back history to local cache immediately.
        await _persistConversation(
          chatHistory: rolledBackHistory,
          sessionId: state.currentSessionId,
        );

        emit(
          state.copyWith(
            chatHistory: rolledBackHistory,
            status: AgentStatus.failure,
            errorMessage: error.message,
          ),
        );
      },
    );
  }

  Future<void> clearChat() async {
    final initial = AgentState.initial();
    emit(initial);
    await _persistConversation(
      chatHistory: initial.chatHistory,
      sessionId: null,
    );
  }

  Future<void> _restoreConversation() async {
    final cachedHistory = await _safeLoadChatHistory();
    final cachedSessionId = await _safeLoadSessionId();

    if (isClosed || cachedHistory.isEmpty) return;

    emit(
      AgentState.restored(
        chatHistory: cachedHistory,
        currentSessionId: cachedSessionId,
      ),
    );
  }

  Future<String?> _buildLocationAwareQuery(String userText) async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return null;

      return '[System Note: User current location is Lat: ${position.latitude}, Lon: ${position.longitude}] $userText';
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistConversation({
    required List<ChatMessage> chatHistory,
    required String? sessionId,
  }) async {
    try {
      await _localDataSource.saveConversation(
        chatHistory: chatHistory,
        sessionId: sessionId,
      );
    } catch (_) {
      // Local cache should not block the live agent experience.
    }
  }

  Future<List<ChatMessage>> _safeLoadChatHistory() async {
    try {
      return _localDataSource.loadChatHistory();
    } catch (_) {
      return const <ChatMessage>[];
    }
  }

  Future<String?> _safeLoadSessionId() async {
    try {
      return _localDataSource.loadSessionId();
    } catch (_) {
      return null;
    }
  }
}
