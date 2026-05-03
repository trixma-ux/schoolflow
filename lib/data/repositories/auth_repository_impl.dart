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

    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user == null) return null;

    final newUser = UserModel(
      id: userCredential.user!.uid,
      name: name,
      email: email,
      role: role,
      profilePic: '',
      createdAt: DateTime.now(),
      classId: classId,
    );

    // Write to Firestore — rules now allow: create if auth.uid == userId
    try {
      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
    } catch (e) {
      debugPrint('Erreur écriture Firestore lors de l\'inscription: $e');
      // Clean up the Auth user to keep state consistent
      await userCredential.user!.delete();
      throw Exception('Impossible de créer le profil Firestore : $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserDocId', newUser.id);

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
