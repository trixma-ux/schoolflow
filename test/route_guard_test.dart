import 'package:flutter_test/flutter_test.dart';
import 'package:school_flow/core/router/route_guard.dart';
import 'package:school_flow/data/models/user_model.dart';

UserModel user(UserRole role) => UserModel(
      id: 'u', name: 'U', email: 'u@x.com', role: role, profilePic: '', createdAt: DateTime(2026));

void main() {
  String? r(String loc, UserModel? u, {bool loading = false}) =>
      RouteGuard.redirect(location: loc, isLoading: loading, user: u);

  test('non connecté : pages protégées → /login, pages publiques OK', () {
    for (final p in ['/admin', '/teacher', '/student', '/parent', '/admin/x']) {
      expect(r(p, null), '/login');
    }
    expect(r('/', null), isNull);
    expect(r('/login', null), isNull);
  });

  test('pendant le chargement de la session : aucune redirection', () {
    expect(r('/admin', null, loading: true), isNull);
  });

  test('connecté : rôle incorrect → son propre tableau de bord', () {
    expect(r('/admin', user(UserRole.student)), '/student');
    expect(r('/teacher', user(UserRole.parent)), '/parent');
    expect(r('/student', user(UserRole.teacher)), '/teacher');
    expect(r('/parent', user(UserRole.admin)), '/admin');
  });

  test('connecté : bon rôle autorisé, pages publiques et inconnues redirigées', () {
    for (final role in UserRole.values) {
      final home = RouteGuard.dashboardFor(role);
      expect(r(home, user(role)), isNull);
      expect(r('/', user(role)), home);
      expect(r('/login', user(role)), home);
      expect(r('/nimporte-quoi', user(role)), home);
    }
  });
}
