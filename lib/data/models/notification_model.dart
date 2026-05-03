import 'package:equatable/equatable.dart';

enum NotificationType { general, assignment, grade, absence, message }

class NotificationModel extends Equatable {
  final String id;
  final String receiverId;
  final String senderId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;

  const NotificationModel({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    required this.type,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NotificationModel(
      id: documentId,
      receiverId: map['receiverId'] ?? '',
      senderId: map['senderId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiverId': receiverId,
      'senderId': senderId,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
    };
  }

  @override
  List<Object?> get props => [id, receiverId, senderId, title, message, createdAt, isRead, type];
}
