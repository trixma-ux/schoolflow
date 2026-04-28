import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String id;
  final String name; // e.g. "Terminal S"
  final String academicYear; // e.g. "2023-2024"
  final List<String> teacherIds;
  final List<String> studentIds;

  const ClassModel({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.teacherIds,
    required this.studentIds,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ClassModel(
      id: documentId,
      name: map['name'] ?? '',
      academicYear: map['academicYear'] ?? '',
      teacherIds: map['teacherIds'] != null ? List<String>.from(map['teacherIds']) : [],
      studentIds: map['studentIds'] != null ? List<String>.from(map['studentIds']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'academicYear': academicYear,
      'teacherIds': teacherIds,
      'studentIds': studentIds,
    };
  }

  @override
  List<Object?> get props => [id, name, academicYear, teacherIds, studentIds];
}
