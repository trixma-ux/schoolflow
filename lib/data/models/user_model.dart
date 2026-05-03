import 'package:equatable/equatable.dart';

enum UserRole { admin, teacher, student, parent }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String profilePic;
  final DateTime createdAt;

  final List<String>? studentIds;
  final String? classId;
  final String? parentId;
  final List<String>? classIds;
  final String? subjectId;
  final List<String>? subjectIds;
  final String? filiere;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profilePic,
    required this.createdAt,
    this.studentIds,
    this.classId,
    this.parentId,
    this.classIds,
    this.subjectId,
    this.subjectIds,
    this.filiere,
  });

  List<String> get effectiveSubjectIds {
    if (subjectIds != null && subjectIds!.isNotEmpty) return subjectIds!;
    if (subjectId != null && subjectId!.isNotEmpty) return [subjectId!];
    return [];
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.student,
      ),
      profilePic: map['profilePic'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      studentIds: map['studentIds'] != null ? List<String>.from(map['studentIds']) : null,
      classId: map['classId'],
      parentId: map['parentId'],
      classIds: map['classIds'] != null ? List<String>.from(map['classIds']) : null,
      subjectId: map['subjectId'],
      subjectIds: map['subjectIds'] != null ? List<String>.from(map['subjectIds']) : null,
      filiere: map['filiere'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'profilePic': profilePic,
      'createdAt': createdAt.toIso8601String(),
      if (studentIds != null) 'studentIds': studentIds,
      if (classId != null) 'classId': classId,
      if (parentId != null) 'parentId': parentId,
      if (classIds != null) 'classIds': classIds,
      if (subjectId != null) 'subjectId': subjectId,
      if (subjectIds != null) 'subjectIds': subjectIds,
      if (filiere != null) 'filiere': filiere,
    };
  }

  @override
  List<Object?> get props => [id, name, email, role, profilePic, createdAt, studentIds, classId, parentId, classIds, subjectId, subjectIds, filiere];
}
