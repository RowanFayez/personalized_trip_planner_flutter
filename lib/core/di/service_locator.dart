import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/api_constants.dart';
import '../network/dio_factory.dart';
import '../services/auth_service.dart';
import '../services/route_preferences_service.dart';
import '../services/user_activity_service.dart';
import '../storage/hive/hive_service.dart';
import '../../features/preferences/data/managers/preferences_manager.dart';
import '../../features/routing/data/datasources/routes_remote_data_source.dart';
import '../../features/routing/data/remote/routes_api_service.dart';
import '../../features/routing/data/repositories/routes_repository_impl.dart';
import '../../features/routing/domain/repositories/routes_repository.dart';
import '../../features/routing/domain/usecases/get_routes_usecase.dart';
import '../../features/routing/presentation/cubit/routing_cubit.dart';

final GetIt sl = GetIt.instance;

class ServiceLocator {
  ServiceLocator._();

  static Future<void> init() async {
    // Hive
    await HiveService.init();

    // Auth
    sl.registerLazySingleton<AuthService>(
      () => AuthService(),
      dispose: (svc) => svc.dispose(),
    );
    sl<AuthService>().init();

    // User activity (last search / last route)
    sl.registerLazySingleton<UserActivityService>(
      () => UserActivityService(authService: sl<AuthService>()),
    );

    // Core
    sl.registerLazySingleton<Dio>(
      () => DioFactory.create(
        authService: sl<AuthService>(),
        baseUrl: ApiConstants.baseUrl,
      ),
    );
    sl.registerLazySingleton<RoutePreferencesService>(
      () => RoutePreferencesService(),
    );
    sl.registerLazySingleton<PreferencesManager>(
      () =>
          PreferencesManager(preferencesService: sl<RoutePreferencesService>()),
    );

    // Routing (data)
    sl.registerLazySingleton<RoutesApiService>(
      () => RoutesApiService(sl<Dio>(), baseUrl: ApiConstants.baseUrl),
    );
    sl.registerLazySingleton<RoutesRemoteDataSource>(
      () => RoutesRemoteDataSource(dio: sl<Dio>()),
    );
    sl.registerLazySingleton<RoutesRepository>(
      () => RoutesRepositoryImpl(remote: sl<RoutesRemoteDataSource>()),
    );

    // Routing (domain)
    sl.registerLazySingleton<GetRoutesUseCase>(
      () => GetRoutesUseCase(sl<RoutesRepository>()),
    );

    // Routing (presentation)
    sl.registerFactory<RoutingCubit>(
      () => RoutingCubit(
        getRoutesUseCase: sl<GetRoutesUseCase>(),
        preferencesManager: sl<PreferencesManager>(),
      ),
    );
  }
}
