import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/crowdsourcing_constants.dart';
import '../di/service_locator.dart';
import '../../features/agent/presentation/cubit/agent_cubit.dart';
import '../../features/agent/presentation/view/agent_chat_page.dart';
import '../../features/routing/presentation/cubit/routing_cubit.dart';
import '../../features/crowdsourcing/presentation/view/fare_feedback_page.dart';
import '../../features/gps_routes_crowdsourcing/data/models/trip_metadata_model.dart';
import '../../features/gps_routes_crowdsourcing/data/services/crowdsourcing_permissions_service.dart';
import '../../features/gps_routes_crowdsourcing/data/services/trip_local_data_source.dart';
import '../../features/gps_routes_crowdsourcing/presentation/cubit/recording_cubit.dart';
import '../../features/gps_routes_crowdsourcing/presentation/views/contributions_page.dart';
import '../../features/gps_routes_crowdsourcing/presentation/views/crowdsourcing_map_page.dart';
import '../../features/gps_routes_crowdsourcing/presentation/views/review_page.dart';
import '../../features/gps_routes_crowdsourcing/presentation/widgets/android_permissions_gate.dart';
import '../../presentation/features/auth/presentation/view/profile_page.dart';
import '../../presentation/features/home/presentation/view/home_page.dart';
import '../../presentation/features/map_picker/presentation/view/map_picker_page.dart';
import '../../presentation/features/preferences/presentation/view/route_preferences_page.dart';

class AppRouter {
  AppRouter._();

  static String? _pendingReviewTripId;

  static Future<void> checkPendingReview() async {
    if (!sl.isRegistered<TripLocalDataSource>()) return;
    _pendingReviewTripId = await sl<TripLocalDataSource>()
        .consumePendingReviewTripId();
  }

  static Future<void> openPendingReviewIfAny() async {
    if (!sl.isRegistered<TripLocalDataSource>()) return;
    final tripId = await sl<TripLocalDataSource>().consumePendingReviewTripId();
    if (tripId == null || tripId.trim().isEmpty) return;
    router.go('${CrowdsourcingRoutes.review}/$tripId');
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final currentPath = state.uri.path;
      if (currentPath.startsWith(CrowdsourcingRoutes.review)) return null;

      final pending = _pendingReviewTripId;
      if (pending != null && pending.trim().isNotEmpty) {
        _pendingReviewTripId = null;
        return '${CrowdsourcingRoutes.review}/$pending';
      }
      return null;
    },
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
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/agent',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<AgentCubit>(),
            child: const AgentChatPage(),
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
      GoRoute(
        path: '/fare-feedback',
        builder: (context, state) {
          final isTotalRoute =
              state.uri.queryParameters['isTotalRoute'] == 'true';
          final legName = state.uri.queryParameters['legName'];
          return FareFeedbackPage(isTotalRoute: isTotalRoute, legName: legName);
        },
      ),
      GoRoute(
        path: CrowdsourcingRoutes.record,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<RecordingCubit>(),
            child: AndroidPermissionsGate(
              permissionsService: sl<CrowdsourcingPermissionsService>(),
              child: const CrowdsourcingMapPage(),
            ),
          );
        },
      ),
      GoRoute(
        path: '${CrowdsourcingRoutes.review}/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId'];
          if (tripId == null || tripId.trim().isEmpty) {
            return const ContributionsPage();
          }
          return ReviewLookupPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: CrowdsourcingRoutes.review,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! TripMetadataModel) return const ContributionsPage();
          return ReviewPage(tripMeta: extra);
        },
      ),
      GoRoute(
        path: CrowdsourcingRoutes.contributions,
        builder: (context, state) => const ContributionsPage(),
      ),
    ],
  );
}
