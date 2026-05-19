import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { donor, organization }

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final bool isVerified;
  final String? location;
  final String? story;
  final String? idNumber;
  final List<String> savedCases;
  final List<String> followedCases;
  final String? fcmToken;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.photoUrl,
    required this.role,
    this.isVerified = false,
    this.location,
    this.story,
    this.idNumber,
    this.savedCases = const [],
    this.followedCases = const [],
    this.fcmToken,
    this.notificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOrganization => role == UserRole.organization;
  bool get isDonor => role == UserRole.donor;

  String get displayName => fullName;

  List<String> get savedCampaigns => savedCases;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final roleStr = data['role'] as String? ?? 'donor';
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      role: (roleStr == 'organization' || roleStr == 'needy')
          ? UserRole.organization
          : UserRole.donor,
      isVerified: data['isVerified'] ?? false,
      location: data['location'],
      story: data['story'],
      idNumber: data['idNumber'],
      savedCases: List<String>.from(
          data['savedCases'] ?? data['savedCampaigns'] ?? []),
      followedCases: List<String>.from(
          data['followedCases'] ?? data['supportedCampaigns'] ?? []),
      fcmToken: data['fcmToken'],
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role == UserRole.organization ? 'organization' : 'donor',
      'isVerified': isVerified,
      'location': location,
      'story': story,
      'idNumber': idNumber,
      'savedCases': savedCases,
      'followedCases': followedCases,
      'fcmToken': fcmToken,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? photoUrl,
    UserRole? role,
    bool? isVerified,
    String? location,
    String? story,
    String? idNumber,
    List<String>? savedCases,
    List<String>? followedCases,
    String? fcmToken,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      location: location ?? this.location,
      story: story ?? this.story,
      idNumber: idNumber ?? this.idNumber,
      savedCases: savedCases ?? this.savedCases,
      followedCases: followedCases ?? this.followedCases,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, email, fullName, role, isVerified, savedCases, followedCases];
}
