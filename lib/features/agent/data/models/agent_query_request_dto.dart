class AgentQueryRequestDto {
  final String userQuery;
  final String? sessionId;

  const AgentQueryRequestDto({required this.userQuery, this.sessionId});

  Map<String, dynamic> toJson() {
    final trimmedSessionId = sessionId?.trim();

    return <String, dynamic>{
      'user_query': userQuery,
      if (trimmedSessionId != null && trimmedSessionId.isNotEmpty)
        'session_id': trimmedSessionId,
    };
  }
}
