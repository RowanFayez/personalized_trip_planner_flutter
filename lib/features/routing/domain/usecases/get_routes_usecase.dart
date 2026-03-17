import '../../../../core/network/api_result.dart';
import '../entities/routing_entities.dart';
import '../repositories/routes_repository.dart';

class GetRoutesUseCase {
  final RoutesRepository _repository;

  const GetRoutesUseCase(this._repository);

  Future<ApiResult<RoutingResult>> call(RoutesRequest request) {
    return _repository.getRoutes(request);
  }
}
