class ComplaintModel {
  final String id;
  final String studentId;
  final String studentName;
  final String type;
  final String subjectId;
  final String description;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;

  const ComplaintModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.subjectId,
    required this.description,
    required this.status,
    this.adminResponse,
    required this.createdAt,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ComplaintModel(
      id: documentId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      type: map['type'] ?? 'other',
      subjectId: map['subjectId'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      adminResponse: map['adminResponse'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'type': type,
      'subjectId': subjectId,
      'description': description,
      'status': status,
      if (adminResponse != null) 'adminResponse': adminResponse,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
