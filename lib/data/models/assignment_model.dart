import 'package:equatable/equatable.dart';

class AssignmentModel extends Equatable {
  final String id;
  final String classId;
  final String subjectId;
  final String teacherId;
  final String title;
  final String description;
  final DateTime dueDate;
  final List<String> attachments; // URLs from Firebase Storage

  const AssignmentModel({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.attachments = const [],
  });

  factory AssignmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AssignmentModel(
      id: documentId,
      classId: map['classId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now(),
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'attachments': attachments,
    };
  }

  @override
  List<Object?> get props => [id, classId, subjectId, teacherId, title, description, dueDate, attachments];
}
