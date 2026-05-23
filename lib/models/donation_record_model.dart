import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum DonationType { campaign, kafala }

class DonationRecord extends Equatable {
  final String id;
  final DonationType type;
  final String campaignId;
  final String campaignTitle;
  final String? needyName;
  final String donorId;
  final String donorName;
  final String organizationId;
  final String orgName;
  final double amount;
  final DateTime createdAt;
  final String? note;

  const DonationRecord({
    required this.id,
    required this.type,
    required this.campaignId,
    required this.campaignTitle,
    this.needyName,
    required this.donorId,
    required this.donorName,
    required this.organizationId,
    required this.orgName,
    required this.amount,
    required this.createdAt,
    this.note,
  });

  bool get isKafala => type == DonationType.kafala;

  String get typeLabel =>
      type == DonationType.kafala ? 'كفالة' : 'حملة';

  factory DonationRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonationRecord(
      id: doc.id,
      type: data['type'] == 'kafala'
          ? DonationType.kafala
          : DonationType.campaign,
      campaignId: data['campaignId'] ?? '',
      campaignTitle: data['campaignTitle'] ?? '',
      needyName: data['needyName'],
      donorId: data['donorId'] ?? '',
      donorName: data['donorName'] ?? '',
      organizationId: data['organizationId'] ?? '',
      orgName: data['orgName'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'campaignId': campaignId,
      'campaignTitle': campaignTitle,
      'needyName': needyName,
      'donorId': donorId,
      'donorName': donorName,
      'organizationId': organizationId,
      'orgName': orgName,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
    };
  }

  @override
  List<Object?> get props =>
      [id, campaignId, donorId, amount, createdAt];
}
