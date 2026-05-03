import 'package:equatable/equatable.dart';

class SubmissionModel extends Equatable {
  final String id;
  final String assignmentId;
  final String studentId;
  final DateTime submittedAt;
  final List<String> attachments; // URLs from Firebase
  final double? grade;
  final String? feedback;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.submittedAt,
    this.attachments = const [],
    this.grade,
    this.feedback,
  });

  factory SubmissionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubmissionModel(
      id: documentId,
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      submittedAt: map['submittedAt'] != null ? DateTime.parse(map['submittedAt']) : DateTime.now(),
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : [],
      grade: map['grade'] != null ? (map['grade'] as num).toDouble() : null,
      feedback: map['feedback'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'submittedAt': submittedAt.toIso8601String(),
      'attachments': attachments,
      if (grade != null) 'grade': grade,
      if (feedback != null) 'feedback': feedback,
    };
  }

  @override
  List<Object?> get props => [id, assignmentId, studentId, submittedAt, attachments, grade, feedback];
}
