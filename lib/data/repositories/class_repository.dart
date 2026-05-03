import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/class_model.dart';

class ClassRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'classes';

  // Créer ou mettre à jour une classe
  Future<void> saveClass(ClassModel classModel) async {
    try {
      await _firestore.collection(_collection).doc(classModel.id).set(classModel.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la classe : $e');
    }
  }

  // Obtenir toutes les classes
  Future<List<ClassModel>> getAllClasses() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) => ClassModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      return [];
    }
  }

  // Obtenir les classes d'un professeur
  Future<List<ClassModel>> getClassesForTeacher(String teacherId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('teacherIds', arrayContains: teacherId)
          .get();
      return snapshot.docs.map((doc) => ClassModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      return [];
    }
  }

  // Obtenir la classe d'un élève
  Future<ClassModel?> getClassForStudent(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('studentIds', arrayContains: studentId)
          .limit(1)
          .get();
          
      if (snapshot.docs.isNotEmpty) {
        return ClassModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    return null;
  }

  // Ajouter un étudiant à une classe
  Future<void> addStudentToClass(String classId, String studentId) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'studentIds': FieldValue.arrayUnion([studentId])
      });
      // Mettre à jour l'étudiant
      await _firestore.collection('users').doc(studentId).update({
        'classId': classId
      });
    } catch (e) {
      throw Exception('Impossible d\'ajouter l\'étudiant à la classe');
    }
  }

  // Assigner un professeur à une classe
  Future<void> assignTeacherToClass(String classId, String teacherId) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'teacherIds': FieldValue.arrayUnion([teacherId])
      });
    } catch (e) {
      throw Exception('Impossible d\'assigner le professeur à la classe');
    }
  }
}
