import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/service_locator.dart';
import '../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../presentation/features/home/presentation/view/home_page.dart';
import '../../presentation/features/map_picker/presentation/view/map_picker_page.dart';
import '../../presentation/features/preferences/presentation/view/route_preferences_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<RoutingCubit>(),
            child: const HomePage(),
          );
        },
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, state) => const RoutePreferencesPage(),
      ),
      GoRoute(
        path: '/map-picker/:field',
        builder: (context, state) {
          final field = state.pathParameters['field'] ?? 'from';
          return MapPickerPage(fieldLabel: field);
        },
      ),
    ],
  );
}
