import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RequestStatus { pending, reviewed, approved, rejected }

class DonorRequestModel extends Equatable {
  final String id;
  final String donorId;
  final String donorName;
  final String? donorPhone;
  final String? donorEmail;
  final String campaignId;
  final String campaignTitle;
  final String organizationId;
  final String? message;
  final RequestStatus status;
  final String? organizationNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DonorRequestModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    this.donorPhone,
    this.donorEmail,
    required this.campaignId,
    required this.campaignTitle,
    required this.organizationId,
    this.message,
    this.status = RequestStatus.pending,
    this.organizationNote,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:
        return 'قيد المراجعة';
      case RequestStatus.reviewed:
        return 'تمت المراجعة';
      case RequestStatus.approved:
        return 'تمت الموافقة';
      case RequestStatus.rejected:
        return 'مرفوض';
    }
  }

  factory DonorRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonorRequestModel(
      id: doc.id,
      donorId: data['donorId'] ?? '',
      donorName: data['donorName'] ?? '',
      donorPhone: data['donorPhone'],
      donorEmail: data['donorEmail'],
      campaignId: data['campaignId'] ?? '',
      campaignTitle: data['campaignTitle'] ?? '',
      organizationId: data['organizationId'] ?? '',
      message: data['message'],
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      organizationNote: data['organizationNote'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'donorPhone': donorPhone,
      'donorEmail': donorEmail,
      'campaignId': campaignId,
      'campaignTitle': campaignTitle,
      'organizationId': organizationId,
      'message': message,
      'status': status.name,
      'organizationNote': organizationNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, status];
}
