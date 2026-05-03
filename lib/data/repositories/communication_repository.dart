import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class CommunicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _firestore.collection(_collection).doc(notification.id).set(notification.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification');
    }
  }

  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('receiverId', isEqualTo: userId)
          .get();
      final list = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Impossible de marquer la notification comme lue');
    }
  }
}
