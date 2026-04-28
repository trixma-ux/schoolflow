import 'package:equatable/equatable.dart';

enum GradeType { exam, quiz, homework }

class GradeModel extends Equatable {
  final String id;
  final String studentId;
  final String subjectId;
  final String teacherId;
  final double score;
  final double maxScore;
  final GradeType type;
  final DateTime date;
  final String? comment;

  const GradeModel({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.score,
    required this.maxScore,
    required this.type,
    required this.date,
    this.comment,
  });

  factory GradeModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GradeModel(
      id: documentId,
      studentId: map['studentId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      score: (map['score'] ?? 0).toDouble(),
      maxScore: (map['maxScore'] ?? 20).toDouble(),
      type: GradeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GradeType.exam,
      ),
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      comment: map['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'score': score,
      'maxScore': maxScore,
      'type': type.name,
      'date': date.toIso8601String(),
      if (comment != null) 'comment': comment,
    };
  }

  @override
  List<Object?> get props => [id, studentId, subjectId, teacherId, score, maxScore, type, date, comment];
}
