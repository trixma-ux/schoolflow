import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/class_model.dart';

class ClassRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'classes';

  Future<void> saveClass(ClassModel classModel) async {
    try {
      await _firestore.collection(_collection).doc(classModel.id).set(classModel.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la classe : $e');
    }
  }

  Future<List<ClassModel>> getAllClasses() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) => ClassModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      return [];
    }
  }

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

  Future<void> addStudentToClass(String classId, String studentId) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'studentIds': FieldValue.arrayUnion([studentId])
      });
      await _firestore.collection('users').doc(studentId).update({'classId': classId});
    } catch (e) {
      throw Exception('Impossible d\'ajouter l\'étudiant à la classe');
    }
  }

  Future<void> removeStudentFromClass(String classId, String studentId) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'studentIds': FieldValue.arrayRemove([studentId])
      });
      await _firestore.collection('users').doc(studentId).update({'classId': null});
    } catch (e) {
      throw Exception('Impossible de retirer l\'étudiant de la classe');
    }
  }

  Future<void> assignTeacherToClass(String classId, String teacherId) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'teacherIds': FieldValue.arrayUnion([teacherId])
      });
    } catch (e) {
      throw Exception('Impossible d\'assigner le professeur à la classe');
    }
  }

  Future<void> removeTeacherFromClass(String classId, String teacherId) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'teacherIds': FieldValue.arrayRemove([teacherId])
      });
    } catch (e) {
      throw Exception('Impossible de retirer le professeur de la classe');
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      final classDoc = await _firestore.collection(_collection).doc(classId).get();
      if (classDoc.exists) {
        final data = classDoc.data()!;
        final studentIds = List<String>.from(data['studentIds'] ?? []);
        final batch = _firestore.batch();
        for (final sid in studentIds) {
          batch.update(_firestore.collection('users').doc(sid), {'classId': null});
        }
        batch.delete(_firestore.collection(_collection).doc(classId));
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Impossible de supprimer la classe : $e');
    }
  }
}
