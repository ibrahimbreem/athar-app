import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum CampaignCategory {
  medical,
  education,
  food,
  housing,
  orphan,
  disaster,
  environment,
  other,
}

enum UrgencyLevel { high, medium, low }

enum KafalaType { orphan, universityStudent, needyFamily, patient }

enum CampaignStatus {
  pending,
  verified,
  inProgress,
  resolved,
  closed,
  available,
  sponsored,
}

class CampaignUpdate {
  final String id;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  const CampaignUpdate({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory CampaignUpdate.fromMap(Map<String, dynamic> map) {
    return CampaignUpdate(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class CampaignModel extends Equatable {
  final String id;
  final String needyUserId;
  final String needyName;
  final String? needyPhotoUrl;
  final bool isVerified;
  final String? verificationNote;
  final String title;
  final String description;
  final String? needs;
  final String? location;
  final List<String> imageUrls;
  final CampaignCategory category;
  final UrgencyLevel urgencyLevel;
  final CampaignStatus status;
  final List<CampaignUpdate> updates;
  final int followersCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  // Kafala-specific fields
  final int? personAge;
  final KafalaType? kafalaType;
  final String? sponsorId;
  final String? sponsorName;
  // ─── Financial fields ─────────────────────────────────────────
  // Campaigns: goalAmount = target, collectedAmount = raised so far
  // Kafala:    monthlyAmount = monthly sponsorship amount
  final double? goalAmount;
  final double collectedAmount;
  final double? monthlyAmount;
  // Organization display name (separate from needyName which is the person)
  final String orgName;

  const CampaignModel({
    required this.id,
    required this.needyUserId,
    required this.needyName,
    this.needyPhotoUrl,
    this.isVerified = false,
    this.verificationNote,
    required this.title,
    required this.description,
    this.needs,
    this.location,
    this.imageUrls = const [],
    required this.category,
    this.urgencyLevel = UrgencyLevel.medium,
    this.status = CampaignStatus.pending,
    this.updates = const [],
    this.followersCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.personAge,
    this.kafalaType,
    this.sponsorId,
    this.sponsorName,
    this.goalAmount,
    this.collectedAmount = 0,
    this.monthlyAmount,
    this.orgName = '',
  });

  // ─── Getters ──────────────────────────────────────────────────
  String get organizationId => needyUserId;
  String get organizationLogoUrl => needyPhotoUrl ?? '';
  bool get organizationVerified => isVerified;
  int get donorsCount => followersCount;

  bool get isKafala => kafalaType != null;
  bool get isAvailable => status == CampaignStatus.available;
  bool get isSponsored => status == CampaignStatus.sponsored;
  bool get isCompleted => status == CampaignStatus.resolved || isSponsored;
  bool get isActive =>
      status == CampaignStatus.verified ||
      status == CampaignStatus.inProgress ||
      isAvailable;
  bool get isPending => status == CampaignStatus.pending;
  bool get isUrgent => urgencyLevel == UrgencyLevel.high;

  /// Real progress for campaigns; falls back to status-based value for old data.
  double get progressPercentage {
    if (!isKafala && goalAmount != null && goalAmount! > 0) {
      return (collectedAmount / goalAmount!).clamp(0.0, 1.0);
    }
    switch (status) {
      case CampaignStatus.resolved:
        return 1.0;
      case CampaignStatus.inProgress:
        return 0.5;
      default:
        return 0.1;
    }
  }

  int get progressPercent => (progressPercentage * 100).round();

  String get statusLabel {
    switch (status) {
      case CampaignStatus.pending:
        return 'قيد المراجعة';
      case CampaignStatus.verified:
        return 'موثقة';
      case CampaignStatus.inProgress:
        return 'جارٍ المساعدة';
      case CampaignStatus.resolved:
        return 'تم الحل';
      case CampaignStatus.closed:
        return 'مغلقة';
      case CampaignStatus.available:
        return 'متاح للكفالة';
      case CampaignStatus.sponsored:
        return 'مكفول';
    }
  }

  String get kafalaTypeLabel {
    switch (kafalaType) {
      case KafalaType.orphan:
        return 'يتيم';
      case KafalaType.universityStudent:
        return 'طالب جامعة';
      case KafalaType.needyFamily:
        return 'أسرة محتاجة';
      case KafalaType.patient:
        return 'مريض';
      case null:
        return '';
    }
  }

  String get categoryLabel {
    switch (category) {
      case CampaignCategory.medical:
        return 'طبي';
      case CampaignCategory.education:
        return 'تعليمي';
      case CampaignCategory.food:
        return 'غذاء';
      case CampaignCategory.housing:
        return 'مسكن';
      case CampaignCategory.orphan:
        return 'أيتام';
      case CampaignCategory.disaster:
        return 'كوارث';
      case CampaignCategory.environment:
        return 'بيئة';
      case CampaignCategory.other:
        return 'أخرى';
    }
  }

  String get urgencyLabel {
    switch (urgencyLevel) {
      case UrgencyLevel.high:
        return 'عاجل';
      case UrgencyLevel.medium:
        return 'متوسط';
      case UrgencyLevel.low:
        return 'عادي';
    }
  }

  String? get thumbnailUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory CampaignModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CampaignModel(
      id: doc.id,
      needyUserId: data['needyUserId'] ?? data['organizationId'] ?? '',
      needyName: data['needyName'] ?? data['organizationName'] ?? '',
      needyPhotoUrl: data['needyPhotoUrl'] ?? data['organizationLogoUrl'],
      isVerified: data['isVerified'] ?? data['organizationVerified'] ?? false,
      verificationNote: data['verificationNote'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      needs: data['needs'],
      location: data['location'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: _categoryFromString(data['category']),
      urgencyLevel: _urgencyFromString(data['urgencyLevel']),
      status: _statusFromString(data['status']),
      updates: (data['updates'] as List<dynamic>? ?? [])
          .map((u) => CampaignUpdate.fromMap(u as Map<String, dynamic>))
          .toList(),
      followersCount: data['followersCount'] ?? data['donorsCount'] ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      personAge: data['personAge'],
      kafalaType: _kafalaTypeFromString(data['kafalaType']),
      sponsorId: data['sponsorId'],
      sponsorName: data['sponsorName'],
      goalAmount: (data['goalAmount'] as num?)?.toDouble(),
      collectedAmount: (data['collectedAmount'] as num?)?.toDouble() ?? 0,
      monthlyAmount: (data['monthlyAmount'] as num?)?.toDouble(),
      orgName: data['orgName'] ?? data['needyName'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'needyUserId': needyUserId,
      'needyName': needyName,
      'needyPhotoUrl': needyPhotoUrl,
      'isVerified': isVerified,
      'verificationNote': verificationNote,
      'title': title,
      'description': description,
      'needs': needs,
      'location': location,
      'imageUrls': imageUrls,
      'category': category.name,
      'urgencyLevel': urgencyLevel.name,
      'status': status.name,
      'updates': updates.map((u) => u.toMap()).toList(),
      'followersCount': followersCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'personAge': personAge,
      'kafalaType': kafalaType?.name,
      'sponsorId': sponsorId,
      'sponsorName': sponsorName,
      'goalAmount': goalAmount,
      'collectedAmount': collectedAmount,
      'monthlyAmount': monthlyAmount,
      'orgName': orgName,
    };
  }

  CampaignModel copyWith({
    String? id,
    String? needyUserId,
    String? needyName,
    String? needyPhotoUrl,
    bool? isVerified,
    String? verificationNote,
    String? title,
    String? description,
    String? needs,
    String? location,
    List<String>? imageUrls,
    CampaignCategory? category,
    UrgencyLevel? urgencyLevel,
    CampaignStatus? status,
    List<CampaignUpdate>? updates,
    int? followersCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? personAge,
    KafalaType? kafalaType,
    String? sponsorId,
    String? sponsorName,
    double? goalAmount,
    double? collectedAmount,
    double? monthlyAmount,
    String? orgName,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      needyUserId: needyUserId ?? this.needyUserId,
      needyName: needyName ?? this.needyName,
      needyPhotoUrl: needyPhotoUrl ?? this.needyPhotoUrl,
      isVerified: isVerified ?? this.isVerified,
      verificationNote: verificationNote ?? this.verificationNote,
      title: title ?? this.title,
      description: description ?? this.description,
      needs: needs ?? this.needs,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      status: status ?? this.status,
      updates: updates ?? this.updates,
      followersCount: followersCount ?? this.followersCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      personAge: personAge ?? this.personAge,
      kafalaType: kafalaType ?? this.kafalaType,
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorName: sponsorName ?? this.sponsorName,
      goalAmount: goalAmount ?? this.goalAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      orgName: orgName ?? this.orgName,
    );
  }

  static CampaignCategory _categoryFromString(String? value) {
    return CampaignCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CampaignCategory.other,
    );
  }

  static UrgencyLevel _urgencyFromString(String? value) {
    return UrgencyLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UrgencyLevel.medium,
    );
  }

  static CampaignStatus _statusFromString(String? value) {
    if (value == 'active') return CampaignStatus.verified;
    if (value == 'completed') return CampaignStatus.resolved;
    return CampaignStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CampaignStatus.pending,
    );
  }

  static KafalaType? _kafalaTypeFromString(String? value) {
    if (value == null) return null;
    return KafalaType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => KafalaType.orphan,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        status,
        followersCount,
        kafalaType,
        collectedAmount,
        monthlyAmount,
      ];
}
