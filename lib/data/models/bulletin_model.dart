import 'package:equatable/equatable.dart';

class BulletinModel extends Equatable {
  final String id;
  final String studentId;
  final String classId;
  final String period; // e.g., "Trimestre 1", "Semestre 1"
  final String academicYear; // e.g., "2023-2024"
  final Map<String, double> subjectAverages; // Map de subjectId -> Moyenne
  final double globalAverage;
  final String? appreciation;
  final DateTime generatedAt;

  const BulletinModel({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.period,
    required this.academicYear,
    required this.subjectAverages,
    required this.globalAverage,
    this.appreciation,
    required this.generatedAt,
  });

  factory BulletinModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BulletinModel(
      id: documentId,
      studentId: map['studentId'] ?? '',
      classId: map['classId'] ?? '',
      period: map['period'] ?? '',
      academicYear: map['academicYear'] ?? '',
      subjectAverages: map['subjectAverages'] != null 
          ? Map<String, double>.from(map['subjectAverages'].map((k, v) => MapEntry(k, (v as num).toDouble()))) 
          : {},
      globalAverage: map['globalAverage'] != null ? (map['globalAverage'] as num).toDouble() : 0.0,
      appreciation: map['appreciation'],
      generatedAt: map['generatedAt'] != null ? DateTime.parse(map['generatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'classId': classId,
      'period': period,
      'academicYear': academicYear,
      'subjectAverages': subjectAverages,
      'globalAverage': globalAverage,
      if (appreciation != null) 'appreciation': appreciation,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, studentId, classId, period, academicYear, subjectAverages, globalAverage, appreciation, generatedAt];
}
