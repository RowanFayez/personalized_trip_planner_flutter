import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message.dart';

enum AgentStatus { idle, loading, success, failure }

class AgentState extends Equatable {
  final List<ChatMessage> chatHistory;
  final AgentStatus status;
  final String? currentSessionId;
  final String? errorMessage;

  const AgentState({
    required this.chatHistory,
    required this.status,
    this.currentSessionId,
    this.errorMessage,
  });

  factory AgentState.initial() {
    return AgentState(
      chatHistory: <ChatMessage>[
        ChatMessage(
          text: 'ازيك عايز تعرف اي من الاسطا ؟',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      status: AgentStatus.idle,
    );
  }

  AgentState copyWith({
    List<ChatMessage>? chatHistory,
    AgentStatus? status,
    String? currentSessionId,
    bool clearSessionId = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AgentState(
      chatHistory: chatHistory ?? this.chatHistory,
      status: status ?? this.status,
      currentSessionId: clearSessionId
          ? null
          : (currentSessionId ?? this.currentSessionId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    chatHistory,
    status,
    currentSessionId,
    errorMessage,
  ];
}
