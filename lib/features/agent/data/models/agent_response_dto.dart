import '../../domain/entities/agent_reply.dart';

class AgentResponseDto {
  final String answer;
  final String sessionId;

  const AgentResponseDto({required this.answer, required this.sessionId});

  factory AgentResponseDto.fromJson(Map<String, dynamic> json) {
    return AgentResponseDto(
      answer: (json['answer'] as String?)?.trim() ?? '',
      sessionId: (json['session_id'] as String?)?.trim() ?? '',
    );
  }

  AgentReply toEntity() {
    return AgentReply(answer: answer, sessionId: sessionId);
  }
}
