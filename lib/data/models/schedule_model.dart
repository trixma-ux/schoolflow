import 'package:equatable/equatable.dart';

class ScheduleModel extends Equatable {
  final String id;
  final String classId;
  final String subjectId;
  final String teacherId;
  final String room;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime; // "08:00"
  final String endTime; // "10:00"

  const ScheduleModel({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ScheduleModel(
      id: documentId,
      classId: map['classId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      room: map['room'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? 1,
      startTime: map['startTime'] ?? '00:00',
      endTime: map['endTime'] ?? '00:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'room': room,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  @override
  List<Object?> get props => [id, classId, subjectId, teacherId, room, dayOfWeek, startTime, endTime];
}
