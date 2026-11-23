import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/logic/school_rules.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';

class ClassRepository {
  ClassRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;
  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  /// Message affiché quand les règles refusent une 6ᵉ classe à un professeur.
  static String tooManyClassesMessage(String teacherName) =>
      '$teacherName enseigne déjà dans ${SchoolRules.maxClassesPerTeacher} classes : '
      'impossible d\'en ajouter une 6ᵉ. Retirez-le d\'abord d\'une autre classe.';
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

  /// Ajoute l'élève à la classe de façon atomique (WriteBatch) :
  /// `classes/{id}.studentIds` et `users/{uid}.classId` sont écrits ensemble,
  /// ce que les règles d'auto-affectation exigent.
  Future<void> addStudentToClass(String classId, String studentId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection(_collection).doc(classId), {
        'studentIds': FieldValue.arrayUnion([studentId])
      });
      batch.update(_firestore.collection('users').doc(studentId), {'classId': classId});
      await batch.commit();
    } catch (e) {
      debugPrint('addStudentToClass: $e');
      throw Exception('Impossible d\'ajouter l\'élève à la classe.');
    }
  }

  Future<void> removeStudentFromClass(String classId, String studentId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection(_collection).doc(classId), {
        'studentIds': FieldValue.arrayRemove([studentId])
      });
      batch.update(_firestore.collection('users').doc(studentId), {'classId': null});
      await batch.commit();
    } catch (e) {
      debugPrint('removeStudentFromClass: $e');
      throw Exception('Impossible de retirer l\'élève de la classe.');
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
        throw Exception(tooManyClassesMessage(teacher.name));
      }
    }
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection(_collection).doc(classId), {
        'teacherIds': FieldValue.arrayUnion([teacherId])
      });
      batch.update(_firestore.collection('users').doc(teacherId), {
        'classIds': FieldValue.arrayUnion([classId])
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      // Les règles plafonnent users.classIds à 5 (classIdsWithinLimit).
      if (e.code == 'permission-denied') {
        throw Exception(tooManyClassesMessage(
            (teacherDoc.data()?['name'] as String?) ?? 'Ce professeur'));
      }
      throw Exception('Impossible d\'assigner le professeur à la classe.');
    } catch (e) {
      throw Exception('Impossible d\'assigner le professeur à la classe.');
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
      final batch = _firestore.batch();
      batch.update(_firestore.collection(_collection).doc(classId), {
        'teacherIds': FieldValue.arrayRemove([teacherId])
      });
      batch.update(_firestore.collection('users').doc(teacherId), {
        'classIds': FieldValue.arrayRemove([classId])
      });
      await batch.commit();
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
