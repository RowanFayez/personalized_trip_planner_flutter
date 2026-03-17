import '../../../../core/network/api_result.dart';
import '../entities/routing_entities.dart';

abstract class RoutesRepository {
  Future<ApiResult<RoutingResult>> getRoutes(RoutesRequest request);
}
