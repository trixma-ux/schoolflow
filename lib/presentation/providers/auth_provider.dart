import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/class_repository.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  /// Nom de la classe attribuée automatiquement lors de la dernière
  /// inscription d'élève (null si aucune).
  String? lastAutoAssignedClassName;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Re-fetches the current user from Firestore and updates the state.
  /// Call this after any profile update (e.g. teacher saving classIds).
  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email, password);
      state = AsyncValue.data(user);
      return user != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, UserRole role, {String? filiere}) async {
    state = const AsyncValue.loading();
    try {
      var user = await _repository.register(name, email, password, role, filiere: filiere);
      lastAutoAssignedClassName = null;
      if (user != null && role == UserRole.student && filiere != null) {
        // Affectation automatique à une classe de la filière (si les règles
        // Firestore l'autorisent ; sinon l'admin la fera depuis son tableau).
        try {
          final cls = await ClassRepository().autoAssignStudent(user);
          if (cls != null) {
            lastAutoAssignedClassName = cls.name;
            user = await _repository.getCurrentUser() ?? user;
          }
        } catch (_) {}
      }
      state = AsyncValue.data(user);
      return user != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
