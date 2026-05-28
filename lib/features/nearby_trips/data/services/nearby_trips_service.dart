import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/api_constants.dart';
import '../../domain/entities/nearby_route.dart';
import '../models/nearby_trip_dto.dart';

class NearbyTripsService {
  final Dio _dio;

  NearbyTripsService({Dio? dio}) : _dio = dio ?? GetIt.I<Dio>();

  /// Calls `POST /api/v1/nearby-trips` and returns unique routes grouped by
  /// `route_name_ar`, keeping the smallest `distance_m` per route.
  Future<List<NearbyRoute>> getNearbyRoutes({
    required double latitude,
    required double longitude,
    double radiusM = 500,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.nearbyTripsEndpoint,
      data: <String, dynamic>{
        'lat': latitude,
        'lon': longitude,
        'radius_m': radiusM,
      },
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is! Map) return const <NearbyRoute>[];

    final tripsJson = data['trips'];
    if (tripsJson is! List) return const <NearbyRoute>[];

    final grouped = <String, NearbyRoute>{};

    for (final item in tripsJson) {
      if (item is! Map) continue;
      final dto = NearbyTripDto.fromJson(Map<String, dynamic>.from(item));

      final routeNameAr = (dto.routeNameAr ?? '').trim();
      if (routeNameAr.isEmpty) continue;

      final candidate = NearbyRoute(
        routeNameAr: routeNameAr,
        routeShortNameAr: (dto.routeShortNameAr ?? '').trim().isNotEmpty
            ? dto.routeShortNameAr!.trim()
            : null,
        distanceM: dto.distanceM,
      );

      final existing = grouped[routeNameAr];
      if (existing == null ||
          candidate.distanceMOrInf < existing.distanceMOrInf) {
        grouped[routeNameAr] = candidate;
      }
    }

    final routes = grouped.values.toList(growable: false);
    routes.sort((a, b) => a.distanceMOrInf.compareTo(b.distanceMOrInf));

    return List<NearbyRoute>.unmodifiable(routes);
  }
}
