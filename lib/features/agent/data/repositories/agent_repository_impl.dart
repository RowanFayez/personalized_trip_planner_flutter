import '../../../../core/network/api_result.dart';
import '../../domain/entities/agent_reply.dart';
import '../../domain/repositories/agent_repository.dart';
import '../models/agent_query_request_dto.dart';
import '../remote/agent_api_service.dart';

class AgentRepositoryImpl implements AgentRepository {
  final AgentApiService _api;

  const AgentRepositoryImpl({required AgentApiService api}) : _api = api;

  @override
  Future<ApiResult<AgentReply>> sendQuery({
    required String userQuery,
    String? sessionId,
  }) {
    return safeApiCall(() async {
      final response = await _api.query(
        AgentQueryRequestDto(userQuery: userQuery, sessionId: sessionId),
      );

      return response.toEntity();
    });
  }
}
