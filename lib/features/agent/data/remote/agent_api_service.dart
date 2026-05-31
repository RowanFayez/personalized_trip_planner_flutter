import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../models/agent_query_request_dto.dart';
import '../models/agent_response_dto.dart';

class AgentApiService {
  final Dio _dio;

  const AgentApiService(this._dio);

  Future<AgentResponseDto> query(AgentQueryRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.agentQueryEndpoint,
      data: request.toJson(),
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Agent response was empty.');
    }

    return AgentResponseDto.fromJson(data);
  }
}
