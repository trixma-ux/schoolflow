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

// Provides the list of all classes
final classesProvider = StreamProvider<List<ClassModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.collection('classes').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => ClassModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Provides the list of all subjects
final subjectsProvider = StreamProvider<List<SubjectModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.collection('subjects').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => SubjectModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Provides the list of all users (for admin)
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.collection('users').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Provides the student's assignments
final studentAssignmentsProvider = StreamProvider.family<List<AssignmentModel>, String>((ref, classId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
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
  if (firestore == null) return Stream.value([]);
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
  if (firestore == null) return Stream.value([]);
  return firestore
      .collection('schedules')
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => ScheduleModel.fromMap(doc.data(), doc.id)).toList();
  });
});

// Provides notifications for a given user
final notificationsProvider = StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore
      .collection('notifications')
      .where('receiverId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList();
  });
});
