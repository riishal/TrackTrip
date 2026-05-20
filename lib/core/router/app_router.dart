import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:track_tripp/data/services/auth_service.dart';
import 'package:track_tripp/providers/app_providers.dart';
import 'package:track_tripp/features/auth/screens/login_screen.dart';
import 'package:track_tripp/features/auth/screens/member_login_screen.dart';
import 'package:track_tripp/features/splash/splash_screen.dart';
import 'package:track_tripp/features/home/screens/home_screen.dart';
import 'package:track_tripp/features/trips/screens/trip_detail_screen.dart';
import 'package:track_tripp/features/trips/screens/create_trip_screen.dart';
import 'package:track_tripp/features/members/screens/members_screen.dart';
import 'package:track_tripp/features/members/screens/add_member_screen.dart';
import 'package:track_tripp/features/members/screens/member_details_screen.dart';
import 'package:track_tripp/features/expenses/screens/expenses_screen.dart';
import 'package:track_tripp/features/expenses/screens/add_expense_screen.dart';
import 'package:track_tripp/features/payments/screens/payments_screen.dart';
import 'package:track_tripp/features/payments/screens/add_payment_screen.dart';
import 'package:track_tripp/features/analytics/screens/analytics_screen.dart';
import 'package:track_tripp/features/member_view/screens/member_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final memberSession = ref.watch(memberSessionProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.value;
      final hasMemberSession = memberSession != null;
      final currentPath = state.uri.path;
      final isAdminLoggedIn = prefs.getBool('admin_logged_in') ?? false;

      // If auth is loading but member session exists, allow access
      if (isLoading && !hasMemberSession && currentPath != '/splash') {
        return '/splash';
      }

      if (currentPath == '/splash' && !isLoading) {
        if (user != null || isAdminLoggedIn) return '/home';
        if (hasMemberSession) return '/member-dashboard';
        return '/login';
      }

      // If already logged in, do not show login or member-login again
      if ((user != null || isAdminLoggedIn) && (currentPath == '/login' || currentPath == '/member-login')) {
        return '/home';
      }
      if (hasMemberSession && (currentPath == '/login' || currentPath == '/member-login')) {
        return '/member-dashboard';
      }

      // Admin user accessing member routes - redirect to home
      if ((user != null || isAdminLoggedIn) && currentPath == '/member-dashboard') {
        return '/home';
      }

      // Member session accessing admin routes - redirect to member-dashboard
      if (hasMemberSession && 
          !currentPath.startsWith('/member') &&
          currentPath != '/login' &&
          currentPath != '/member-login' &&
          currentPath != '/splash') {
        return '/member-dashboard';
      }

      final authPaths = ['/login', '/member-login', '/splash'];
      if (user == null &&
          !isAdminLoggedIn &&
          !hasMemberSession &&
          !authPaths.contains(currentPath)) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/member-login',
        builder: (_, _) => const MemberLoginScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/trip/:tripId',
        builder: (_, state) =>
            TripDetailScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/create-trip',
        builder: (_, _) => const CreateTripScreen(),
      ),
      GoRoute(
        path: '/edit-trip/:tripId',
        builder: (_, state) =>
            CreateTripScreen(editTripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trip/:tripId/members',
        builder: (_, state) =>
            MembersScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trip/:tripId/add-member',
        builder: (_, state) =>
            AddMemberScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trip/:tripId/edit-member/:memberId',
        builder: (_, state) => AddMemberScreen(
          tripId: state.pathParameters['tripId']!,
          editMemberId: state.pathParameters['memberId']!,
        ),
      ),
      GoRoute(
        path: '/trip/:tripId/member/:memberId',
        builder: (_, state) => MemberDetailsScreen(
          tripId: state.pathParameters['tripId']!,
          memberId: state.pathParameters['memberId']!,
        ),
      ),
      GoRoute(
        path: '/trip/:tripId/expenses',
        builder: (_, state) =>
            ExpensesScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trip/:tripId/add-expense',
        builder: (_, state) =>
            AddExpenseScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trip/:tripId/edit-expense/:expenseId',
        builder: (_, state) => AddExpenseScreen(
          tripId: state.pathParameters['tripId']!,
          editExpenseId: state.pathParameters['expenseId']!,
        ),
      ),
      GoRoute(
        path: '/trip/:tripId/payments',
        builder: (_, state) =>
            PaymentsScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trip/:tripId/add-payment',
        builder: (_, state) =>
            AddPaymentScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trip/:tripId/edit-payment/:paymentId',
        builder: (_, state) => AddPaymentScreen(
          tripId: state.pathParameters['tripId']!,
          editPaymentId: state.pathParameters['paymentId']!,
        ),
      ),
      GoRoute(
        path: '/trip/:tripId/analytics',
        builder: (_, state) =>
            AnalyticsScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/member-dashboard',
        builder: (_, _) => const MemberDashboardScreen(),
      ),
    ],
  );
});
