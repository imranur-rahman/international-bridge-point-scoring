import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../scoring/scoring.dart';
import 'features/deal_screen.dart';
import 'features/edit_deal_screen.dart';
import 'features/home_screen.dart';
import 'features/house_rules_screen.dart';
import 'features/past_sessions_screen.dart';
import 'features/score_sheet.dart';
import 'features/settings_screen.dart';
import 'features/setup_wizard.dart';
import 'features/summary_screen.dart';
import 'providers.dart';

/// The routes of the app (design decision D7).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.uri.path;
      final needsSession =
          path == '/deal' ||
          path == '/summary' ||
          path.startsWith('/edit/') ||
          path == '/sheet';
      if (needsSession && session == null) return '/';
      if (path == '/deal' &&
          session != null &&
          session.isEnded &&
          session.draft == null) {
        return '/summary';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/setup',
        builder: (_, _) => const SetupWizard(),
        routes: [
          GoRoute(
            path: 'house-rules',
            builder: (_, state) => HouseRulesScreen(
              preset:
                  state.uri.queryParameters['preset'] ==
                      ScoringPreset.standard.name
                  ? ScoringPreset.standard
                  : ScoringPreset.houseRules,
            ),
          ),
        ],
      ),
      GoRoute(path: '/deal', builder: (_, _) => const DealScreen()),
      GoRoute(
        path: '/sheet',
        builder: (_, state) => SheetScreen(
          readOnly: state.uri.queryParameters['readOnly'] == 'true',
        ),
      ),
      GoRoute(
        path: '/edit/:index',
        builder: (_, state) => EditDealScreen(
          index: int.tryParse(state.pathParameters['index']!) ?? -1,
        ),
      ),
      GoRoute(path: '/summary', builder: (_, _) => const SummaryScreen()),
      GoRoute(
        path: '/past',
        builder: (_, _) => const PastSessionsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                SummaryScreen(pastId: state.pathParameters['id']),
            routes: [
              GoRoute(
                path: 'sheet',
                builder: (_, state) =>
                    SheetScreen(pastId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});
