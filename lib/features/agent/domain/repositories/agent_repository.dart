import '../../../../core/network/api_result.dart';
import '../entities/agent_reply.dart';

abstract class AgentRepository {
  Future<ApiResult<AgentReply>> sendQuery({
    required String userQuery,
    String? sessionId,
  });
}
