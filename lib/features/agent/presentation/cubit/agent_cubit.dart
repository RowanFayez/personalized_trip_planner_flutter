import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/agent_repository.dart';
import 'agent_state.dart';

class AgentCubit extends Cubit<AgentState> {
  final AgentRepository _repository;
  final LocationService _locationService;

  AgentCubit({
    required AgentRepository repository,
    required LocationService locationService,
  }) : _repository = repository,
       _locationService = locationService,
       super(AgentState.initial());

  Future<void> sendMessage(String text) async {
    final userText = text.trim();
    if (userText.isEmpty || state.status == AgentStatus.loading) return;

    final userMessage = ChatMessage(
      text: userText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final nextHistory = List<ChatMessage>.unmodifiable([
      ...state.chatHistory,
      userMessage,
    ]);

    emit(
      state.copyWith(
        chatHistory: nextHistory,
        status: AgentStatus.loading,
        clearError: true,
      ),
    );

    final backendQuery = await _queryWithLocation(userText);
    final result = await _repository.sendQuery(
      userQuery: backendQuery,
      sessionId: state.currentSessionId,
    );

    result.when(
      success: (reply) {
        final agentMessage = ChatMessage(
          text: reply.answer.trim().isEmpty
              ? AppStrings.agentFallbackAnswer
              : reply.answer.trim(),
          isUser: false,
          timestamp: DateTime.now(),
        );

        emit(
          state.copyWith(
            chatHistory: List<ChatMessage>.unmodifiable([
              ...state.chatHistory,
              agentMessage,
            ]),
            status: AgentStatus.success,
            currentSessionId: reply.sessionId.trim().isEmpty
                ? state.currentSessionId
                : reply.sessionId.trim(),
            clearError: true,
          ),
        );
      },
      failure: (error) {
        emit(
          state.copyWith(
            status: AgentStatus.failure,
            errorMessage: error.message,
          ),
        );
      },
    );
  }

  Future<String> _queryWithLocation(String userText) async {
    final position = await _locationService.getCurrentLocation();
    if (position == null) return userText;

    return '[User Location: ${position.latitude}, ${position.longitude}] $userText';
  }

  void clearChat() {
    emit(AgentState.initial());
  }
}
