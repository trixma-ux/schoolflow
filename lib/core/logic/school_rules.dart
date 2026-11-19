import '../../data/models/class_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/user_model.dart';
import '../data/filieres_ci.dart';

/// Règles métier SchoolFlow (fonctions pures, testables sans Firebase).
class SchoolRules {
  SchoolRules._();

  /// Un professeur enseigne dans 5 classes au maximum (cahier des charges).
  static const int maxClassesPerTeacher = 5;

  static String? _norm(String? f) {
    final v = f?.trim().toUpperCase();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Classes d'un professeur : union de son profil (`classIds`) et des
  /// classes qui le listent dans `teacherIds`.
  static Set<String> teacherClassIds(UserModel teacher, List<ClassModel> classes) {
    return {
      ...?teacher.classIds,
      for (final c in classes)
        if (c.teacherIds.contains(teacher.id)) c.id,
    };
  }

  /// Vrai si le professeur peut encore être affecté à [classId].
  static bool canAssignTeacher(UserModel teacher, List<ClassModel> classes, String classId) {
    final current = teacherClassIds(teacher, classes);
    if (current.contains(classId)) return true;
    return current.length < maxClassesPerTeacher;
  }

  /// Classe à attribuer automatiquement à un élève de filière [filiere] :
  /// même filière, non pleine, la moins remplie (puis ordre alphabétique).
  /// Retourne null s'il n'y a aucune classe compatible.
  static ClassModel? pickClassForFiliere(String? filiere, List<ClassModel> classes) {
    final f = _norm(filiere);
    if (f == null) return null;
    final candidates = classes
        .where((c) => _norm(c.filiere) == f && !c.isFull)
        .toList()
      ..sort((a, b) {
        final byCount = a.studentIds.length.compareTo(b.studentIds.length);
        return byCount != 0 ? byCount : a.name.compareTo(b.name);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Élèves sans classe : ni `classId` valide, ni présents dans une classe.
  /// Triés du plus récent au plus ancien (nouveaux inscrits en premier).
  static List<UserModel> unassignedStudents(List<UserModel> users, List<ClassModel> classes) {
    final classIds = classes.map((c) => c.id).toSet();
    final enrolled = {for (final c in classes) ...c.studentIds};
    final list = users.where((u) {
      if (u.role != UserRole.student) return false;
      if (enrolled.contains(u.id)) return false;
      final cid = u.classId;
      return cid == null || cid.isEmpty || !classIds.contains(cid);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Plan d'affectation automatique : élève → classe, en respectant les
  /// capacités au fil des affectations. Les élèves sans classe compatible
  /// sont absents du résultat.
  static Map<UserModel, ClassModel> planAutoAssignment(
      List<UserModel> students, List<ClassModel> classes) {
    final working = [
      for (final c in classes)
        ClassModel(
          id: c.id,
          name: c.name,
          academicYear: c.academicYear,
          teacherIds: c.teacherIds,
          studentIds: List.of(c.studentIds),
          filiere: c.filiere,
          capacity: c.capacity,
        )
    ];
    final plan = <UserModel, ClassModel>{};
    for (final s in students) {
      final target = pickClassForFiliere(s.filiere, working);
      if (target == null) continue;
      target.studentIds.add(s.id);
      plan[s] = classes.firstWhere((c) => c.id == target.id);
    }
    return plan;
  }

  /// Nom lisible d'une matière (Firestore, sinon référentiel CI).
  static String subjectName(String subjectId, List<SubjectModel> subjects) {
    for (final s in subjects) {
      if (s.id == subjectId) return s.name;
    }
    for (final f in filieresCi) {
      for (final s in f.subjects) {
        if (s.id == subjectId) return s.name;
      }
    }
    return subjectId;
  }

  /// Pour une classe : quelle(s) matière(s) enseigne quel professeur.
  /// Les matières de la filière sans professeur apparaissent avec une liste
  /// vide afin que l'élève sache qu'aucun enseignant n'est encore affecté.
  static List<SubjectTeachers> teachersBySubject({
    required ClassModel cls,
    required List<UserModel> users,
    required List<SubjectModel> subjects,
    String? studentFiliere,
  }) {
    final teachers = users.where((u) =>
        u.role == UserRole.teacher &&
        ((u.classIds?.contains(cls.id) ?? false) || cls.teacherIds.contains(u.id)));
    final bySubject = <String, List<UserModel>>{};
    for (final t in teachers) {
      final ids = t.effectiveSubjectIds;
      if (ids.isEmpty) {
        bySubject.putIfAbsent('', () => []).add(t);
      }
      for (final sid in ids) {
        bySubject.putIfAbsent(sid, () => []).add(t);
      }
    }
    final filiere = _norm(cls.filiere) ?? _norm(studentFiliere);
    if (filiere != null) {
      for (final f in filieresCi) {
        if (_norm(f.id) == filiere) {
          for (final s in f.subjects) {
            bySubject.putIfAbsent(s.id, () => []);
          }
        }
      }
    }
    final result = bySubject.entries
        .map((e) => SubjectTeachers(
              subjectId: e.key,
              subjectName: e.key.isEmpty ? 'Matière non renseignée' : subjectName(e.key, subjects),
              teacherNames: e.value.map((t) => t.name).toList()..sort(),
            ))
        .toList()
      ..sort((a, b) {
        if (a.teacherNames.isEmpty != b.teacherNames.isEmpty) {
          return a.teacherNames.isEmpty ? 1 : -1;
        }
        return a.subjectName.compareTo(b.subjectName);
      });
    return result;
  }
}

class SubjectTeachers {
  final String subjectId;
  final String subjectName;
  final List<String> teacherNames;
  const SubjectTeachers({required this.subjectId, required this.subjectName, required this.teacherNames});
}
