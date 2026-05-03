import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/class_model.dart';
import '../../data/models/assignment_model.dart';
import '../../data/models/grade_model.dart';
import '../../data/models/schedule_model.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore?>((ref) {
  try {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  } catch (e) {
    return null;
  }
});

final classesProvider = StreamProvider<List<ClassModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.collection('classes').snapshots().map((s) =>
      s.docs.map((doc) => ClassModel.fromMap(doc.data(), doc.id)).toList());
});

final subjectsProvider = StreamProvider<List<SubjectModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.collection('subjects').snapshots().map((s) =>
      s.docs.map((doc) => SubjectModel.fromMap(doc.data(), doc.id)).toList());
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.collection('users').snapshots().map((s) =>
      s.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
});

final studentAssignmentsProvider = StreamProvider.family<List<AssignmentModel>, String>((ref, classId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || classId.isEmpty) return Stream.value([]);
  return firestore
      .collection('assignments')
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((s) => s.docs.map((doc) => AssignmentModel.fromMap(doc.data(), doc.id)).toList());
});

final studentGradesProvider = StreamProvider.family<List<GradeModel>, String>((ref, studentId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || studentId.isEmpty) return Stream.value([]);
  return firestore
      .collection('grades')
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((s) => s.docs.map((doc) => GradeModel.fromMap(doc.data(), doc.id)).toList());
});

final classScheduleProvider = StreamProvider.family<List<ScheduleModel>, String>((ref, classId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || classId.isEmpty) return Stream.value([]);
  return firestore
      .collection('schedules')
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((s) => s.docs.map((doc) => ScheduleModel.fromMap(doc.data(), doc.id)).toList());
});

// Sorted in Dart to avoid requiring a Firestore composite index
final notificationsProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || userId.isEmpty) return Stream.value([]);
  return firestore
      .collection('notifications')
      .where('receiverId', isEqualTo: userId)
      .snapshots()
      .map((s) {
    final list = s.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

// Teacher-specific grades stream (grades they entered)
final teacherGradesProvider = StreamProvider.family<List<GradeModel>, String>((ref, teacherId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || teacherId.isEmpty) return Stream.value([]);
  return firestore
      .collection('grades')
      .where('teacherId', isEqualTo: teacherId)
      .snapshots()
      .map((s) => s.docs.map((doc) => GradeModel.fromMap(doc.data(), doc.id)).toList());
});
