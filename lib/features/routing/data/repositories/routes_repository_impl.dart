import '../../../../core/network/api_result.dart';
import '../../domain/entities/routing_entities.dart';
import '../../domain/repositories/routes_repository.dart';
import '../datasources/routes_remote_data_source.dart';
import '../mappers/routing_mapper.dart';

class RoutesRepositoryImpl implements RoutesRepository {
  final RoutesRemoteDataSource _remote;

  RoutesRepositoryImpl({RoutesRemoteDataSource? remote})
    : _remote = remote ?? RoutesRemoteDataSource();

  @override
  Future<ApiResult<RoutingResult>> getRoutes(RoutesRequest request) async {
    final result = await _remote.getRoutes(request.toDto());
    return result.when(
      success: (dto) => ApiResult.success(dto.toEntity()),
      failure: (err) => ApiResult.failure(err),
    );
  }
}
