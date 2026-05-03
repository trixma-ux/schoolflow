import 'package:equatable/equatable.dart';

enum AbsenceStatus { justified, unjustified, pending }

class AbsenceModel extends Equatable {
  final String id;
  final String studentId;
  final String teacherId;
  final String classId;
  final DateTime date;
  final AbsenceStatus status;
  final String? reason;

  const AbsenceModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.classId,
    required this.date,
    required this.status,
    this.reason,
  });

  factory AbsenceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AbsenceModel(
      id: documentId,
      studentId: map['studentId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      classId: map['classId'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      status: AbsenceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AbsenceStatus.pending,
      ),
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'teacherId': teacherId,
      'classId': classId,
      'date': date.toIso8601String(),
      'status': status.name,
      if (reason != null) 'reason': reason,
    };
  }

  @override
  List<Object?> get props => [id, studentId, teacherId, classId, date, status, reason];
}
