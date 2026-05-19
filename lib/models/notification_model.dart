import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum NotificationType {
  campaignUpdate,
  donationRequest,
  requestApproved,
  newCampaign,
  general,
}

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? campaignId;
  final String? requestId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.campaignId,
    this.requestId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.general,
      ),
      campaignId: data['campaignId'],
      requestId: data['requestId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'campaignId': campaignId,
      'requestId': requestId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      campaignId: campaignId,
      requestId: requestId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get typeIcon {
    switch (type) {
      case NotificationType.campaignUpdate:
        return '📢';
      case NotificationType.donationRequest:
        return '🤝';
      case NotificationType.requestApproved:
        return '✅';
      case NotificationType.newCampaign:
        return '🆕';
      case NotificationType.general:
        return '🔔';
    }
  }

  @override
  List<Object?> get props => [id, isRead];
}
