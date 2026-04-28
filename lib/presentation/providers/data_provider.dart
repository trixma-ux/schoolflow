import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/class_model.dart';
import '../../data/models/assignment_model.dart';
import '../../data/models/grade_model.dart';
import '../../data/models/schedule_model.dart';

final isFirebaseReadyProvider = StateProvider<bool>((ref) => false);

final firebaseFirestoreProvider = Provider<FirebaseFirestore?>((ref) {
  final isReady = ref.watch(isFirebaseReadyProvider);
  return isReady ? FirebaseFirestore.instance : null;
});

// Provides the list of all classes
final classesProvider = StreamProvider<List<ClassModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return Stream.value([
      const ClassModel(id: 'c1', name: 'Terminal S', academicYear: '2023-2024', studentIds: [], teacherIds: []),
      const ClassModel(id: 'c2', name: 'Première ES', academicYear: '2023-2024', studentIds: [], teacherIds: []),
      const ClassModel(id: 'c3', name: 'Seconde', academicYear: '2023-2024', studentIds: [], teacherIds: []),
    ]);
  }
  return firestore.collection('classes').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => ClassModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Provides the student's assignments
final studentAssignmentsProvider = StreamProvider.family<List<AssignmentModel>, String>((ref, classId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return Stream.value([
      AssignmentModel(id: 'a1', title: 'Exercices Mathématiques', description: 'Faire les exercices page 42.', dueDate: DateTime.now().add(const Duration(days: 2)), subjectId: 'maths', classId: classId, teacherId: 't1'),
    ]);
  }
  return firestore
      .collection('assignments')
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => AssignmentModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Provides the student's grades
final studentGradesProvider = StreamProvider.family<List<GradeModel>, String>((ref, studentId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return Stream.value([
      GradeModel(id: 'g1', studentId: studentId, subjectId: 'maths', teacherId: 't1', score: 15.5, maxScore: 20, type: GradeType.exam, date: DateTime.now()),
      GradeModel(id: 'g2', studentId: studentId, subjectId: 'physique', teacherId: 't2', score: 12, maxScore: 20, type: GradeType.homework, date: DateTime.now()),
    ]);
  }
  return firestore
      .collection('grades')
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => GradeModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Provides schedule for a given class
final classScheduleProvider = StreamProvider.family<List<ScheduleModel>, String>((ref, classId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return Stream.value([
      ScheduleModel(id: 's1', classId: classId, subjectId: 'maths', teacherId: 't1', dayOfWeek: 1, startTime: '08:00', endTime: '10:00', room: 'B12'),
      ScheduleModel(id: 's2', classId: classId, subjectId: 'physique', teacherId: 't2', dayOfWeek: 1, startTime: '10:00', endTime: '12:00', room: 'Lab 2'),
    ]);
  }
  return firestore
      .collection('schedules')
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => ScheduleModel.fromMap(doc.data(), doc.id)).toList();
  });
});
