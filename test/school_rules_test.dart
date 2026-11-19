import 'package:flutter_test/flutter_test.dart';
import 'package:school_flow/core/logic/school_rules.dart';
import 'package:school_flow/data/models/class_model.dart';
import 'package:school_flow/data/models/user_model.dart';

UserModel student(String id, {String? filiere, String? classId, int day = 1}) => UserModel(
      id: id,
      name: 'Élève $id',
      email: '$id@student.com',
      role: UserRole.student,
      profilePic: '',
      createdAt: DateTime(2026, 1, day),
      filiere: filiere,
      classId: classId,
    );

UserModel teacher(String id, {List<String>? classIds, List<String>? subjectIds}) => UserModel(
      id: id,
      name: 'Prof $id',
      email: '$id@teacher.com',
      role: UserRole.teacher,
      profilePic: '',
      createdAt: DateTime(2026),
      classIds: classIds,
      subjectIds: subjectIds,
    );

ClassModel cls(String id, {String? filiere, List<String> students = const [], List<String> teachers = const [], int? capacity}) =>
    ClassModel(
      id: id,
      name: 'Classe $id',
      academicYear: '2025-2026',
      teacherIds: teachers,
      studentIds: students,
      filiere: filiere,
      capacity: capacity,
    );

void main() {
  group('pickClassForFiliere', () {
    test('choisit la classe de la filière la moins remplie', () {
      final classes = [
        cls('c1', filiere: 'C', students: ['a', 'b']),
        cls('c2', filiere: 'C', students: ['x']),
        cls('d1', filiere: 'D'),
      ];
      expect(SchoolRules.pickClassForFiliere('C', classes)!.id, 'c2');
      expect(SchoolRules.pickClassForFiliere('d', classes)!.id, 'd1');
    });

    test('ignore les classes pleines et gère l\'absence de classe compatible', () {
      final classes = [cls('c1', filiere: 'C', students: ['a'], capacity: 1)];
      expect(SchoolRules.pickClassForFiliere('C', classes), isNull);
      expect(SchoolRules.pickClassForFiliere('A', classes), isNull);
      expect(SchoolRules.pickClassForFiliere(null, classes), isNull);
    });
  });

  test('planAutoAssignment respecte la capacité au fil des affectations', () {
    final classes = [cls('c1', filiere: 'C', capacity: 2, students: ['old'])];
    final s = [student('1', filiere: 'C'), student('2', filiere: 'C'), student('3', filiere: 'A')];
    final plan = SchoolRules.planAutoAssignment(s, classes);
    expect(plan.length, 1);
    expect(plan.keys.single.id, '1');
    // La classe d'origine n'est pas modifiée.
    expect(classes.first.studentIds, ['old']);
  });

  test('unassignedStudents liste les élèves sans classe, plus récents d\'abord', () {
    final classes = [cls('c1', students: ['in'])];
    final users = [
      student('in', classId: 'c1'),
      student('old', day: 1),
      student('new', day: 9),
      student('ghost', classId: 'deleted-class', day: 5),
      teacher('t'),
    ];
    expect(SchoolRules.unassignedStudents(users, classes).map((u) => u.id), ['new', 'ghost', 'old']);
  });

  test('un professeur est limité à 5 classes', () {
    final classes = [for (var i = 0; i < 6; i++) cls('c$i', teachers: i < 3 ? ['t'] : [])];
    final t = teacher('t', classIds: ['c3', 'c4']);
    expect(SchoolRules.teacherClassIds(t, classes).length, 5);
    expect(SchoolRules.canAssignTeacher(t, classes, 'c5'), isFalse);
    expect(SchoolRules.canAssignTeacher(t, classes, 'c0'), isTrue);
    expect(SchoolRules.canAssignTeacher(teacher('t2'), classes, 'c5'), isTrue);
  });

  test('teachersBySubject indique quel professeur enseigne quelle matière', () {
    final c = cls('c1', filiere: 'C', teachers: ['t1']);
    final users = [
      teacher('t1', subjectIds: ['C_maths']),
      teacher('t2', classIds: ['c1'], subjectIds: ['C_pc', 'C_maths']),
      teacher('t3', classIds: ['other'], subjectIds: ['C_svt']),
    ];
    final list = SchoolRules.teachersBySubject(cls: c, users: users, subjects: const []);
    final maths = list.firstWhere((e) => e.subjectId == 'C_maths');
    expect(maths.teacherNames, ['Prof t1', 'Prof t2']);
    expect(maths.subjectName, isNot('C_maths'));
    expect(list.firstWhere((e) => e.subjectId == 'C_pc').teacherNames, ['Prof t2']);
    // Les matières de la filière sans professeur sont listées (vides) en dernier.
    final empty = list.where((e) => e.teacherNames.isEmpty).toList();
    expect(empty, isNotEmpty);
    expect(list.indexOf(empty.first), greaterThan(list.indexOf(maths)));
  });
}
