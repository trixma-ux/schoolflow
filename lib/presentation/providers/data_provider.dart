import 'dart:async';
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
import '../../data/models/complaint_model.dart';

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

/// Liste globale des utilisateurs — **réservée aux écrans d'administration**.
/// Les règles Firestore (6895d1f) refusent cette requête non filtrée à tout
/// autre rôle : utiliser les fournisseurs ciblés ci-dessous ailleurs.
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.collection('users').snapshots().map((s) =>
      s.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
});

List<UserModel> _users(QuerySnapshot<Map<String, dynamic>> s) =>
    s.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();

/// Un utilisateur par son id (`users/{uid}`), null s'il n'existe pas.
final userDocProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || uid.isEmpty) return Stream.value(null);
  return firestore.collection('users').doc(uid).snapshots().map((d) =>
      d.exists && d.data() != null ? UserModel.fromMap(d.data()!, d.id) : null);
});

/// Professeurs et administrateurs (lisibles par tous les rôles).
final staffProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore
      .collection('users')
      .where('role', whereIn: ['teacher', 'admin'])
      .snapshots()
      .map(_users);
});

/// Professeurs uniquement (dérivé de [staffProvider]).
final teachersProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  return ref.watch(staffProvider).whenData(
      (list) => list.where((u) => u.role == UserRole.teacher).toList());
});

/// Parents et administrateurs (destinataires de messages d'un professeur).
final parentsAndAdminsProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore
      .collection('users')
      .where('role', whereIn: ['parent', 'admin'])
      .snapshots()
      .map(_users);
});

/// Membres d'une classe (`where classId == X`) : camarades pour un élève,
/// élèves d'une de ses classes pour un professeur.
final classMembersProvider = StreamProvider.family<List<UserModel>, String>((ref, classId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || classId.isEmpty) return Stream.value([]);
  return firestore
      .collection('users')
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map(_users);
});

/// Clé stable pour un ensemble d'ids (les familles Riverpod comparent par ==).
String idsKey(Iterable<String> ids) {
  final list = ids.where((e) => e.isNotEmpty).toSet().toList()..sort();
  return list.join(',');
}

List<String> _splitKey(String key) =>
    key.isEmpty ? const [] : key.split(',');

/// Combine plusieurs flux en un flux de listes (dernière valeur de chacun).
Stream<List<T>> combineLatestList<T>(List<Stream<T>> streams) {
  if (streams.isEmpty) return Stream.value(<T>[]);
  late StreamController<List<T>> controller;
  final values = List<T?>.filled(streams.length, null);
  final has = List<bool>.filled(streams.length, false);
  final subs = <StreamSubscription<T>>[];
  controller = StreamController<List<T>>(
    onListen: () {
      for (var i = 0; i < streams.length; i++) {
        subs.add(streams[i].listen((v) {
          values[i] = v;
          has[i] = true;
          if (has.every((h) => h)) controller.add(List<T>.from(values));
        }, onError: controller.addError));
      }
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}

/// Enfants d'un parent : une lecture `doc()` par enfant (autorisée par
/// isParentOf), clé = [idsKey] des studentIds. Les documents illisibles ou
/// supprimés sont ignorés.
final childrenProvider = StreamProvider.family<List<UserModel>, String>((ref, key) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final ids = _splitKey(key);
  if (firestore == null || ids.isEmpty) return Stream.value([]);
  final streams = ids
      .map((id) => firestore
          .collection('users')
          .doc(id)
          .snapshots()
          .map<UserModel?>((d) => d.exists && d.data() != null
              ? UserModel.fromMap(d.data()!, d.id)
              : null)
          // Refus de lecture / erreur : l'enfant est ignoré sans bloquer les autres.
          .transform(StreamTransformer<UserModel?, UserModel?>.fromHandlers(
              handleError: (Object _, StackTrace __, EventSink<UserModel?> sink) =>
                  sink.add(null))))
      .toList();
  return combineLatestList(streams)
      .map((list) => list.whereType<UserModel>().toList());
});

/// Classes d'un professeur : celles dont `teacherIds` contient son uid (lien
/// faisant autorité pour les règles ; `users.classIds` est auto-déclaré).
final teacherClassesProvider = StreamProvider.family<List<ClassModel>, String>((ref, uid) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || uid.isEmpty) return Stream.value([]);
  return firestore
      .collection('classes')
      .where('teacherIds', arrayContains: uid)
      .snapshots()
      .map((s) => s.docs.map((doc) => ClassModel.fromMap(doc.data(), doc.id)).toList());
});

/// Élèves de plusieurs classes (une requête `classId ==` par classe).
/// Clé = [idsKey] des ids de classes.
final studentsOfClassesProvider = StreamProvider.family<List<UserModel>, String>((ref, key) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final ids = _splitKey(key);
  if (firestore == null || ids.isEmpty) return Stream.value([]);
  final streams = ids
      .map((cid) => firestore
          .collection('users')
          .where('classId', isEqualTo: cid)
          .snapshots()
          .map(_users))
      .toList();
  return combineLatestList(streams).map((lists) => [
        for (final l in lists)
          for (final u in l)
            if (u.role == UserRole.student) u
      ]);
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

final unreadNotificationsCountProvider = Provider.family<int, String>((ref, userId) {
  final notifs = ref.watch(notificationsProvider(userId)).valueOrNull ?? [];
  return notifs.where((n) => !n.isRead).length;
});

final teacherGradesProvider = StreamProvider.family<List<GradeModel>, String>((ref, teacherId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || teacherId.isEmpty) return Stream.value([]);
  return firestore
      .collection('grades')
      .where('teacherId', isEqualTo: teacherId)
      .snapshots()
      .map((s) => s.docs.map((doc) => GradeModel.fromMap(doc.data(), doc.id)).toList());
});

final complaintsProvider = StreamProvider<List<ComplaintModel>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.collection('complaints').snapshots().map((s) {
    final list = s.docs.map((doc) => ComplaintModel.fromMap(doc.data(), doc.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

final studentComplaintsProvider = StreamProvider.family<List<ComplaintModel>, String>((ref, studentId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || studentId.isEmpty) return Stream.value([]);
  return firestore
      .collection('complaints')
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((s) {
    final list = s.docs.map((doc) => ComplaintModel.fromMap(doc.data(), doc.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});
