import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/assignment_model.dart';
import '../models/schedule_model.dart';
import '../models/grade_model.dart';

class DummyData {
  static final List<UserModel> users = [
    UserModel(
      id: 'admin_1',
      name: 'Alice Admin',
      email: 'admin@schoolflow.com',
      role: UserRole.admin,
      profilePic: 'https://i.pravatar.cc/150?u=admin',
      createdAt: DateTime.now(),
    ),
    UserModel(
      id: 'teacher_1',
      name: 'Mr. John Doe',
      email: 'john.doe@schoolflow.com',
      role: UserRole.teacher,
      profilePic: 'https://i.pravatar.cc/150?u=teacher',
      createdAt: DateTime.now(),
    ),
    UserModel(
      id: 'student_1',
      name: 'Leo Student',
      email: 'leo@student.com',
      role: UserRole.student,
      profilePic: 'https://i.pravatar.cc/150?u=leo',
      createdAt: DateTime.now(),
      classId: 'class_1',
      parentId: 'parent_1',
    ),
    UserModel(
      id: 'parent_1',
      name: 'Mrs. Student Mom',
      email: 'mom@parent.com',
      role: UserRole.parent,
      profilePic: 'https://i.pravatar.cc/150?u=mom',
      createdAt: DateTime.now(),
      studentIds: const ['student_1'],
    ),
  ];

  static final List<ClassModel> classes = [
    const ClassModel(
      id: 'class_1',
      name: 'Terminal S',
      academicYear: '2023-2024',
      teacherIds: ['teacher_1'],
      studentIds: ['student_1'],
    )
  ];

  static final List<AssignmentModel> assignments = [
    AssignmentModel(
      id: 'assign_1',
      classId: 'class_1',
      subjectId: 'sub_maths',
      teacherId: 'teacher_1',
      title: 'Equations Différentielles',
      description: 'Faire les exercices 1 à 5 de la page 42.',
      dueDate: DateTime.now().add(const Duration(days: 3)),
    )
  ];

  static final List<GradeModel> grades = [
    GradeModel(
      id: 'grade_1',
      studentId: 'student_1',
      subjectId: 'sub_maths',
      teacherId: 'teacher_1',
      score: 16.5,
      maxScore: 20,
      type: GradeType.exam,
      date: DateTime.now().subtract(const Duration(days: 5)),
      comment: 'Excellent travail.',
    ),
    GradeModel(
      id: 'grade_2',
      studentId: 'student_1',
      subjectId: 'sub_physics',
      teacherId: 'teacher_1',
      score: 14,
      maxScore: 20,
      type: GradeType.quiz,
      date: DateTime.now().subtract(const Duration(days: 2)),
    )
  ];

  static final List<ScheduleModel> schedules = [
    const ScheduleModel(
      id: 'sched_1',
      classId: 'class_1',
      subjectId: 'sub_maths',
      teacherId: 'teacher_1',
      room: 'Salle 101',
      dayOfWeek: 1, // Lundi
      startTime: '08:00',
      endTime: '10:00',
    ),
    const ScheduleModel(
      id: 'sched_2',
      classId: 'class_1',
      subjectId: 'sub_physics',
      teacherId: 'teacher_1',
      room: 'Labo 2',
      dayOfWeek: 1,
      startTime: '10:30',
      endTime: '12:30',
    ),
  ];
}
