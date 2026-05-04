import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> login(String email, String password) async {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase non configuré.');
    }

    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user == null) return null;

    final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
    if (!userDoc.exists || userDoc.data() == null) {
      throw Exception('Profil introuvable. Contactez l\'administrateur.');
    }

    final userModel = UserModel.fromMap(userDoc.data()!, userDoc.id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserDocId', userModel.id);

    return userModel;
  }

  @override
  Future<UserModel?> register(String name, String email, String password, UserRole role, [String? classId]) async {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase non configuré.');
    }

    // Check if there is already a signed-in user (admin creating another user).
    // In that case we use a secondary Firebase app so the current session is
    // NOT interrupted.
    final currentUser = _firebaseAuth.currentUser;
    final bool isAdminCreating = currentUser != null;

    String uid;

    if (isAdminCreating) {
      // ── Secondary-app pattern ──────────────────────────────────────────────
      // Spin up a temporary Firebase app so createUserWithEmailAndPassword
      // does NOT touch the primary auth state.
      final String secondaryAppName = 'secondary_${DateTime.now().millisecondsSinceEpoch}';
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = await Firebase.initializeApp(
          name: secondaryAppName,
          options: Firebase.app().options,
        );

        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        uid = credential.user!.uid;

        // Sign out from secondary app immediately — we don't need it.
        await secondaryAuth.signOut();
      } finally {
        // Always delete the secondary app to free resources.
        try {
          await secondaryApp?.delete();
        } catch (_) {}
      }
    } else {
      // Normal self-registration (no one is logged in).
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) return null;
      uid = credential.user!.uid;
    }

    final newUser = UserModel(
      id: uid,
      name: name,
      email: email,
      role: role,
      profilePic: '',
      createdAt: DateTime.now(),
      classId: classId,
    );

    // Write to Firestore — primary auth is intact so Firestore rules pass.
    try {
      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
    } catch (e) {
      debugPrint('Erreur écriture Firestore lors de l\'inscription: $e');
      // Only delete the Auth account on self-registration; for admin-created
      // accounts the uid belongs to the secondary app which is already deleted.
      if (!isAdminCreating) {
        try {
          await _firebaseAuth.currentUser?.delete();
        } catch (_) {}
      }
      throw Exception('Impossible de créer le profil Firestore : $e');
    }

    // Only update SharedPreferences when the user is registering themselves.
    if (!isAdminCreating) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserDocId', newUser.id);
    }

    return newUser;
  }

  @override
  Future<void> logout() async {
    if (Firebase.apps.isNotEmpty) {
      await _firebaseAuth.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserDocId');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (Firebase.apps.isEmpty) return null;

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return UserModel.fromMap(userDoc.data()!, userDoc.id);
      }
    } catch (e) {
      debugPrint('Erreur récupération utilisateur courant: $e');
    }
    return null;
  }
}
