import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/logic/school_rules.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';

class ClassRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
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

  /// Affecte un professeur à une classe en respectant la limite de
  /// [SchoolRules.maxClassesPerTeacher] classes, et synchronise `classIds`
  /// sur son profil pour qu'il voie la classe dans son tableau de bord.
  Future<void> assignTeacherToClass(String classId, String teacherId) async {
    final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
    if (teacherDoc.exists && teacherDoc.data() != null) {
      final teacher = UserModel.fromMap(teacherDoc.data()!, teacherDoc.id);
      final classes = await getAllClasses();
      if (!SchoolRules.canAssignTeacher(teacher, classes, classId)) {
        throw Exception(
            '${teacher.name} enseigne déjà dans ${SchoolRules.maxClassesPerTeacher} classes (maximum).');
      }
    }
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'teacherIds': FieldValue.arrayUnion([teacherId])
      });
      await _firestore.collection('users').doc(teacherId).update({
        'classIds': FieldValue.arrayUnion([classId])
      });
    } catch (e) {
      throw Exception('Impossible d\'assigner le professeur à la classe');
    }
  }

  /// Affecte automatiquement un élève à une classe de sa filière (non pleine).
  /// Retourne la classe choisie, ou null si aucune classe ne correspond ou si
  /// l'écriture est refusée (l'élève reste alors dans la liste « sans classe »
  /// de l'administration).
  Future<ClassModel?> autoAssignStudent(UserModel student, {List<ClassModel>? classes}) async {
    final all = classes ?? await getAllClasses();
    final target = SchoolRules.pickClassForFiliere(student.filiere, all);
    if (target == null) return null;
    try {
      await addStudentToClass(target.id, student.id);
      return target;
    } catch (e) {
      debugPrint('Affectation automatique impossible : $e');
      return null;
    }
  }

  Future<void> removeTeacherFromClass(String classId, String teacherId) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'teacherIds': FieldValue.arrayRemove([teacherId])
      });
      await _firestore.collection('users').doc(teacherId).update({
        'classIds': FieldValue.arrayRemove([classId])
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
