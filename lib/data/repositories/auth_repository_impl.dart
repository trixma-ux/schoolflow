import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> login(String email, String password) async {
    // [FALLBACK MOCK MODE] Si Firebase n'est pas configuré
    if (Firebase.apps.isEmpty) {
      final mockRole = email.contains('admin') ? UserRole.admin 
          : email.contains('teacher') ? UserRole.teacher
          : email.contains('parent') ? UserRole.parent
          : UserRole.student;
      
      final mockUser = UserModel(
        id: 'mock-user-123',
        name: 'Utilisateur Simulation',
        email: email,
        role: mockRole,
        profilePic: '',
        createdAt: DateTime.now(),
        classId: 'c1',
        studentIds: const ['student-123']
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserDocId', mockUser.id);
      return mockUser;
    }

    try {
      // 1. Authentification Firebase native
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (userCredential.user == null) return null;

      // 2. Récupérer les informations avec Fallback si Firestore n'est pas prêt
      UserModel userModel;
      try {
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (!userDoc.exists || userDoc.data() == null) {
          throw Exception('Not found');
        }
        userModel = UserModel.fromMap(userDoc.data()!, userDoc.id);
      } catch (e) {
        // Fallback de développement si la BDD n'est pas encore bien paramétrée (règles etc.)
        final fallbackRole = email.contains('teacher') ? UserRole.teacher : (email.contains('admin') ? UserRole.admin : UserRole.student);
        userModel = UserModel(
          id: userCredential.user!.uid,
          name: email.split('@').first,
          email: email,
          role: fallbackRole,
          profilePic: '',
          createdAt: DateTime.now(),
        );
      }
      
      // 3. Sauvegarder localement pour l'accès rapide au cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserDocId', userModel.id);
      
      return userModel;
    } catch (e) {
      throw Exception('Échec de la connexion : $e');
    }
  }

  @override
  Future<UserModel?> register(String name, String email, String password, UserRole role, [String? classId]) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, 
        password: password
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
      
      try {
        await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
      } catch (e) {
        // On ignore silencieusement pour le dev local si Firebase Firestore n'a pas les bonnes règles de sécurité
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserDocId', newUser.id);
      
      return newUser;
    } catch (e) {
      throw Exception("Échec de l'inscription : $e");
    }
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
    if (Firebase.apps.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('currentUserDocId');
      if (savedId != null) {
        return UserModel(
          id: savedId,
          name: 'Utilisateur Simulation',
          email: 'admin@school.com',
          role: UserRole.admin,
          profilePic: '',
          createdAt: DateTime.now(),
          classId: 'c1',
          studentIds: const ['student-123']
        );
      }
      return null;
    }

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          return UserModel.fromMap(userDoc.data()!, userDoc.id);
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
