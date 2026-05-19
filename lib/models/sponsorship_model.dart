import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SponsorshipType { orphan, student, family, elderly }

enum SponsorshipStatus { available, sponsoring, completed }

class SponsorshipModel extends Equatable {
  final String id;
  final String organizationId;
  final String organizationName;
  final String? organizationLogoUrl;
  final String name;
  final String description;
  final double monthlyAmount;
  final SponsorshipType type;
  final SponsorshipStatus status;
  final String? imageUrl;
  final int age;
  final String location;
  final String? sponsorId;
  final DateTime createdAt;

  const SponsorshipModel({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    this.organizationLogoUrl,
    required this.name,
    required this.description,
    required this.monthlyAmount,
    required this.type,
    this.status = SponsorshipStatus.available,
    this.imageUrl,
    required this.age,
    required this.location,
    this.sponsorId,
    required this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case SponsorshipType.orphan:
        return 'يتيم';
      case SponsorshipType.student:
        return 'طالب';
      case SponsorshipType.family:
        return 'أسرة';
      case SponsorshipType.elderly:
        return 'مسن';
    }
  }

  bool get isAvailable => status == SponsorshipStatus.available;

  factory SponsorshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SponsorshipModel(
      id: doc.id,
      organizationId: data['organizationId'] ?? '',
      organizationName: data['organizationName'] ?? '',
      organizationLogoUrl: data['organizationLogoUrl'],
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      monthlyAmount: (data['monthlyAmount'] ?? 0).toDouble(),
      type: SponsorshipType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SponsorshipType.orphan,
      ),
      status: SponsorshipStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SponsorshipStatus.available,
      ),
      imageUrl: data['imageUrl'],
      age: data['age'] ?? 0,
      location: data['location'] ?? '',
      sponsorId: data['sponsorId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'organizationId': organizationId,
      'organizationName': organizationName,
      'organizationLogoUrl': organizationLogoUrl,
      'name': name,
      'description': description,
      'monthlyAmount': monthlyAmount,
      'type': type.name,
      'status': status.name,
      'imageUrl': imageUrl,
      'age': age,
      'location': location,
      'sponsorId': sponsorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, status, sponsorId];
}
