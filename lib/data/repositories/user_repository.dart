import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Récupérer un utilisateur par son ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'utilisateur : $e');
    }
    return null;
  }

  // Récupérer tous les utilisateurs par rôle
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('role', isEqualTo: role.name)
          .get();
          
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des utilisateurs : $e');
      return [];
    }
  }

  // Mettre à jour le profil
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).update(user.toMap());
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'utilisateur : $e');
      throw Exception('Impossible de mettre à jour le profil');
    }
  }

  // Lier un étudiant à un parent
  Future<void> linkStudentToParent(String parentId, String studentId) async {
    try {
      // 1. Ajouter le studentId au tableau studentIds du Parent
      await _firestore.collection(_collection).doc(parentId).update({
        'studentIds': FieldValue.arrayUnion([studentId])
      });
      
      // 2. Assigner le parentId à l'Étudiant
      await _firestore.collection(_collection).doc(studentId).update({
        'parentId': parentId
      });
    } catch (e) {
      debugPrint('Erreur lors de la liaison parent-étudiant : $e');
      throw Exception('Impossible de lier l\'étudiant au parent');
    }
  }
}
