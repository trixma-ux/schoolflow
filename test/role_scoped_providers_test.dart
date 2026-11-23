import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_flow/core/data/filieres_ci.dart';
import 'package:school_flow/data/repositories/class_repository.dart';
import 'package:school_flow/presentation/providers/data_provider.dart';

Future<FakeFirebaseFirestore> _seed() async {
  final db = FakeFirebaseFirestore();
  final users = <String, Map<String, dynamic>>{
    'admin1': {'name': 'Admin', 'role': 'admin'},
    'tA': {'name': 'TA', 'role': 'teacher', 'classIds': ['c1']},
    's1': {'name': 'Zoé', 'role': 'student', 'classId': 'c1'},
    's2': {'name': 'Ali', 'role': 'student', 'classId': 'c1'},
    's3': {'name': 'Bia', 'role': 'student', 'classId': 'c2'},
    'sNo': {'name': 'Nou', 'role': 'student', 'filiere': 'C'},
    'p1': {'name': 'P1', 'role': 'parent', 'studentIds': ['s1']},
  };
  for (final e in users.entries) {
    await db.collection('users').doc(e.key).set(e.value);
  }
  await db.collection('classes').doc('c1').set({'name': 'Tle C1', 'filiere': 'C', 'teacherIds': ['tA'], 'studentIds': ['s1', 's2']});
  await db.collection('classes').doc('c2').set({'name': 'Tle D1', 'filiere': 'D', 'teacherIds': ['tB'], 'studentIds': ['s3']});
  await db.collection('classes').doc('c3').set({'name': 'Tle C2', 'filiere': 'C', 'teacherIds': ['tA'], 'studentIds': []});
  return db;
}

ProviderContainer _container(FakeFirebaseFirestore db) {
  final c = ProviderContainer(overrides: [firebaseFirestoreProvider.overrideWithValue(db)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('idsKey trie, dédoublonne et ignore les vides', () {
    expect(idsKey(['b', 'a', '', 'b']), 'a,b');
    expect(idsKey(const []), '');
  });

  test('combineLatestList émet quand chaque flux a une valeur', () async {
    final a = StreamController<int>();
    final b = StreamController<int>();
    final out = <List<int>>[];
    final sub = combineLatestList([a.stream, b.stream]).listen(out.add);
    a.add(1);
    await Future<void>.delayed(Duration.zero);
    expect(out, isEmpty);
    b.add(2);
    a.add(3);
    await Future<void>.delayed(Duration.zero);
    expect(out, [[1, 2], [3, 2]]);
    await sub.cancel();
    expect(await combineLatestList<int>(const []).first, isEmpty);
  });

  test('classMembersProvider : uniquement classId == X', () async {
    final c = _container(await _seed());
    final list = await c.read(classMembersProvider('c1').future);
    expect(list.map((u) => u.id).toSet(), {'s1', 's2'});
    expect(await c.read(classMembersProvider('').future), isEmpty);
  });

  test('staffProvider / teachersProvider / parentsAndAdminsProvider filtrent par rôle', () async {
    final c = _container(await _seed());
    final staff = await c.read(staffProvider.future);
    expect(staff.map((u) => u.id).toSet(), {'admin1', 'tA'});
    expect(c.read(teachersProvider).value!.map((u) => u.id), ['tA']);
    final pa = await c.read(parentsAndAdminsProvider.future);
    expect(pa.map((u) => u.id).toSet(), {'admin1', 'p1'});
  });

  test('userDocProvider : doc par id, null si absent', () async {
    final c = _container(await _seed());
    expect((await c.read(userDocProvider('s1').future))!.name, 'Zoé');
    expect(await c.read(userDocProvider('nope').future), isNull);
  });

  test('childrenProvider : un doc par enfant, enfant absent ignoré', () async {
    final c = _container(await _seed());
    final kids = await c.read(childrenProvider(idsKey(['s1', 'ghost'])).future);
    expect(kids.map((u) => u.id), ['s1']);
  });

  test('teacherClassesProvider : classes.teacherIds array-contains uid', () async {
    final c = _container(await _seed());
    final cls = await c.read(teacherClassesProvider('tA').future);
    expect(cls.map((x) => x.id).toSet(), {'c1', 'c3'});
  });

  test('studentsOfClassesProvider : élèves des classes données', () async {
    final c = _container(await _seed());
    final list = await c.read(studentsOfClassesProvider(idsKey(['c1', 'c2'])).future);
    expect(list.map((u) => u.id).toSet(), {'s1', 's2', 's3'});
  });

  test('ClassRepository.addStudentToClass écrit studentIds et classId ensemble', () async {
    final db = await _seed();
    await ClassRepository(firestore: db).addStudentToClass('c3', 'sNo');
    expect((await db.collection('classes').doc('c3').get()).data()!['studentIds'], ['sNo']);
    expect((await db.collection('users').doc('sNo').get()).data()!['classId'], 'c3');
  });

  test('ClassRepository.assignTeacherToClass refuse une 6ᵉ classe en français', () async {
    final db = await _seed();
    await db.collection('users').doc('tFull').set({'name': 'M. Kouassi', 'role': 'teacher', 'classIds': ['k1', 'k2', 'k3', 'k4', 'k5']});
    for (final k in ['k1', 'k2', 'k3', 'k4', 'k5']) {
      await db.collection('classes').doc(k).set({'name': k, 'teacherIds': ['tFull'], 'studentIds': []});
    }
    await expectLater(
      ClassRepository(firestore: db).assignTeacherToClass('c3', 'tFull'),
      throwsA(predicate((e) => e.toString().contains('impossible d\'en ajouter une 6ᵉ'))),
    );
    expect((await db.collection('classes').doc('c3').get()).data()!['teacherIds'], ['tA']);
  });

  test('canonicalFiliere normalise les variantes', () {
    expect(canonicalFiliere(' série c '), 'C');
    expect(canonicalFiliere('Serie-D'), 'D');
    expect(canonicalFiliere('g 2'), 'G2');
    expect(canonicalFiliere('t_1'), 'T1');
    expect(canonicalFiliere('xyz'), isNull);
    expect(canonicalFiliere(null), isNull);
  });
}
