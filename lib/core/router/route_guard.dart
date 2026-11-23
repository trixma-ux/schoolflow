import '../../data/models/user_model.dart';

/// Gardes de routes côté client (la sécurité réelle reste assurée par les
/// règles Firestore).
class RouteGuard {
  RouteGuard._();

  static const publicPaths = {'/', '/login', '/register'};

  static const Map<UserRole, String> dashboards = {
    UserRole.admin: '/admin',
    UserRole.teacher: '/teacher',
    UserRole.student: '/student',
    UserRole.parent: '/parent',
  };

  static String dashboardFor(UserRole role) => dashboards[role]!;

  /// Rôle requis pour [location], ou null si la page est publique/inconnue.
  static UserRole? requiredRole(String location) {
    for (final e in dashboards.entries) {
      if (location == e.value || location.startsWith('${e.value}/')) return e.key;
    }
    return null;
  }

  /// Calcule la redirection :
  /// - pendant le chargement de la session : pas de redirection ;
  /// - non connecté sur une page protégée → /login ;
  /// - connecté sur une page publique → son tableau de bord ;
  /// - connecté sur le tableau de bord d'un autre rôle → son tableau de bord.
  static String? redirect({
    required String location,
    required bool isLoading,
    required UserModel? user,
  }) {
    if (isLoading) return null;
    final isPublic = publicPaths.contains(location);
    final needed = requiredRole(location);

    if (user == null) {
      if (isPublic) return null;
      return '/login';
    }

    final home = dashboardFor(user.role);
    if (isPublic) return home;
    if (needed != null && needed != user.role) return home;
    if (needed == null) return home; // route inconnue
    return null;
  }
}
