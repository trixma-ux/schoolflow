import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../presentation/providers/auth_provider.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/student/student_dashboard.dart';
import '../../presentation/screens/teacher/teacher_dashboard.dart';
import '../../presentation/screens/admin/admin_dashboard.dart';
import '../../presentation/screens/parent/parent_dashboard.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);

    if (authState.isLoading) return null;

    final user = authState.valueOrNull;
    final isAuthenticated = user != null;
    final isGoingToLogin = state.matchedLocation == '/login';

    if (!isAuthenticated && !isGoingToLogin) return '/login';

    if (isAuthenticated && isGoingToLogin) {
      switch (user.role) {
        case UserRole.admin:
          return '/admin';
        case UserRole.teacher:
          return '/teacher';
        case UserRole.student:
          return '/student';
        case UserRole.parent:
          return '/parent';
      }
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentDashboard(),
      ),
    ],
  );
});
