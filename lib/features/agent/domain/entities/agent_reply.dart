import 'package:equatable/equatable.dart';

class AgentReply extends Equatable {
  final String answer;
  final String sessionId;

  const AgentReply({required this.answer, required this.sessionId});

  @override
  List<Object?> get props => [answer, sessionId];
}
