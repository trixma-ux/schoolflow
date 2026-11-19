import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_flow/data/models/class_model.dart';
import 'package:school_flow/data/models/user_model.dart';
import 'package:school_flow/data/repositories/class_repository.dart';
import 'package:school_flow/presentation/providers/data_provider.dart';
import 'package:school_flow/presentation/screens/admin/unassigned_students_card.dart';

class _FakeRepo extends ClassRepository {
  final calls = <String>[];
  @override
  Future<void> addStudentToClass(String classId, String studentId) async {
    calls.add('$studentId->$classId');
  }
}

void main() {
  testWidgets('affiche les élèves sans classe et les affecte en un clic', (tester) async {
    final users = [
      UserModel(id: 's1', name: 'Awa', email: 'a@s.com', role: UserRole.student, profilePic: '',
          createdAt: DateTime(2026, 1, 2), filiere: 'C'),
      UserModel(id: 's2', name: 'Koffi', email: 'k@s.com', role: UserRole.student, profilePic: '',
          createdAt: DateTime(2026, 1, 1), filiere: 'A'),
    ];
    const classes = [
      ClassModel(id: 'c1', name: 'Tle C1', academicYear: '2025-2026', teacherIds: [], studentIds: [], filiere: 'C'),
    ];
    final repo = _FakeRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        allUsersProvider.overrideWith((ref) => Stream.value(users)),
        classesProvider.overrideWith((ref) => Stream.value(classes)),
      ],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: UnassignedStudentsCard(repository: repo)))),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Élèves sans classe (2)'), findsOneWidget);
    expect(find.textContaining('suggestion : Tle C1'), findsOneWidget);
    expect(find.textContaining('aucune classe compatible'), findsOneWidget);

    await tester.tap(find.byTooltip('Affecter à Tle C1'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['s1->c1']);

    await tester.tap(find.byKey(const ValueKey('assign-all')));
    await tester.pumpAndSettle();
    expect(repo.calls, ['s1->c1', 's1->c1']);
  });
}
