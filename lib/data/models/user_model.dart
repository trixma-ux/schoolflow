import 'package:equatable/equatable.dart';

enum UserRole { admin, teacher, student, parent }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String profilePic;
  final DateTime createdAt;
  
  // Specific to Parents
  final List<String>? studentIds;
  
  // Specific to Students
  final String? classId;
  final String? parentId;

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
  });

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
    };
  }

  @override
  List<Object?> get props => [id, name, email, role, profilePic, createdAt, studentIds, classId, parentId];
}
