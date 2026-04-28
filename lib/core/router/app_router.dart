import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../presentation/providers/auth_provider.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/student/student_dashboard.dart';
import '../../presentation/screens/teacher/teacher_dashboard.dart';
import '../../presentation/screens/admin/admin_dashboard.dart';
import '../../presentation/screens/parent/parent_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Prevent routing during loading states
      if (authState.isLoading) return null;

      // Check if user is authenticated (using valueOrNull to avoid throwing on error)
      final user = authState.valueOrNull;
      final isAuthenticated = user != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      // 1. If not authenticated and not heading to login, redirect to login
      if (!isAuthenticated && !isGoingToLogin) {
        return '/login';
      }

      // 2. If authenticated and heading to login, redirect to their dashboard
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

      // 3. No redirection needed
      return null;
    },
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
