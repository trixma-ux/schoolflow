import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/grade_model.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../models/absence_model.dart';
import '../models/notification_model.dart';
import 'communication_repository.dart';

class AcademicRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- GRADES ---
  Future<void> addGrade(GradeModel grade) async {
    await _firestore.collection('grades').doc(grade.id).set(grade.toMap());
    
    // Notification automatique à l'élève
    try {
      final commRepo = CommunicationRepository();
      await commRepo.sendNotification(NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        receiverId: grade.studentId,
        senderId: grade.teacherId,
        title: 'Nouvelle note en ${grade.subjectId}',
        message: 'Vous avez obtenu ${grade.score}/${grade.maxScore}.',
        createdAt: DateTime.now(),
        type: NotificationType.grade,
      ));
    } catch (e) {
      debugPrint('Erreur d\'envoi de notification de note: $e');
    }
  }

  Future<List<GradeModel>> getGradesForStudent(String studentId) async {
    final snapshot = await _firestore.collection('grades').where('studentId', isEqualTo: studentId).get();
    return snapshot.docs.map((doc) => GradeModel.fromMap(doc.data(), doc.id)).toList();
  }

  // --- ASSIGNMENTS & SUBMISSIONS ---
  Future<void> addAssignment(AssignmentModel assignment) async {
    await _firestore.collection('assignments').doc(assignment.id).set(assignment.toMap());
  }

  Future<List<AssignmentModel>> getAssignmentsForClass(String classId) async {
    final snapshot = await _firestore.collection('assignments').where('classId', isEqualTo: classId).get();
    return snapshot.docs.map((doc) => AssignmentModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> submitAssignment(SubmissionModel submission) async {
    await _firestore.collection('submissions').doc(submission.id).set(submission.toMap());
  }
  
  Future<List<SubmissionModel>> getSubmissionsForAssignment(String assignmentId) async {
    final snapshot = await _firestore.collection('submissions').where('assignmentId', isEqualTo: assignmentId).get();
    return snapshot.docs.map((doc) => SubmissionModel.fromMap(doc.data(), doc.id)).toList();
  }

  // --- ABSENCES ---
  Future<void> reportAbsence(AbsenceModel absence) async {
    await _firestore.collection('absences').doc(absence.id).set(absence.toMap());
  }

  Future<List<AbsenceModel>> getAbsencesForStudent(String studentId) async {
    final snapshot = await _firestore.collection('absences').where('studentId', isEqualTo: studentId).get();
    return snapshot.docs.map((doc) => AbsenceModel.fromMap(doc.data(), doc.id)).toList();
  }
}
