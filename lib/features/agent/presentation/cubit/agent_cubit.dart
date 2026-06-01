import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/location_service.dart';
import '../../data/local/agent_local_data_source.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/agent_repository.dart';
import 'agent_state.dart';

class AgentCubit extends Cubit<AgentState> {
  final AgentRepository _repository;
  final LocationService _locationService;
  final AgentLocalDataSource _localDataSource;
  final AuthService _authService;
  late final Future<void> _restoreFuture;
  StreamSubscription<dynamic>? _authSub;
  String? _activeUserId;

  AgentCubit({
    required AgentRepository repository,
    required LocationService locationService,
    required AgentLocalDataSource localDataSource,
    required AuthService authService,
  }) : _repository = repository,
       _locationService = locationService,
       _localDataSource = localDataSource,
       _authService = authService,
       super(AgentState.initial()) {
    _activeUserId = _authService.uid;
    _restoreFuture = _restoreConversationForUser(_activeUserId);
    _authSub = _authService.authStateChanges().listen(_handleAuthChange);
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    _authSub = null;
    return super.close();
  }

  Future<void> sendMessage(String text) async {
    await _restoreFuture;

    final userId = _activeUserId ?? _authService.uid;
    if (userId == null || userId.trim().isEmpty) {
      return;
    }

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
      userId: userId,
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
        userId: userId,
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
          userId: userId,
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
          userId: userId,
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
    final userId = _activeUserId ?? _authService.uid;
    if (userId == null || userId.trim().isEmpty) return;
    await _persistConversation(
      userId: userId,
      chatHistory: initial.chatHistory,
      sessionId: null,
    );
  }

  Future<void> _restoreConversationForUser(String? userId) async {
    final normalized = userId?.trim();
    if (normalized == null || normalized.isEmpty) {
      emit(AgentState.initial());
      return;
    }

    await _localDataSource.migrateLegacyIfNeeded(userId: normalized);
    final cachedHistory = await _safeLoadChatHistory(normalized);
    final cachedSessionId = await _safeLoadSessionId(normalized);

    if (isClosed) return;
    if (cachedHistory.isEmpty) {
      emit(AgentState.initial());
      return;
    }

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
    required String userId,
    required List<ChatMessage> chatHistory,
    required String? sessionId,
  }) async {
    try {
      await _localDataSource.saveConversation(
        userId: userId,
        chatHistory: chatHistory,
        sessionId: sessionId,
      );
    } catch (_) {
      // Local cache should not block the live agent experience.
    }
  }

  Future<List<ChatMessage>> _safeLoadChatHistory(String userId) async {
    try {
      return _localDataSource.loadChatHistory(userId: userId);
    } catch (_) {
      return const <ChatMessage>[];
    }
  }

  Future<String?> _safeLoadSessionId(String userId) async {
    try {
      return _localDataSource.loadSessionId(userId: userId);
    } catch (_) {
      return null;
    }
  }

  void _handleAuthChange(dynamic user) {
    final nextUserId = _authService.uid;
    if (nextUserId == _activeUserId) return;
    _activeUserId = nextUserId;
    _restoreFuture = _restoreConversationForUser(nextUserId);
  }
}
