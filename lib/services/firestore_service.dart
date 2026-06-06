import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campaign_model.dart';
import '../models/donation_record_model.dart';
import '../models/notification_model.dart';
import '../models/donor_request_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ─────────────────────────────────────────────────────────
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _cases => _db.collection('cases');
  CollectionReference get _notifications => _db.collection('notifications');
  CollectionReference get _follows => _db.collection('follows');
  CollectionReference get _donations => _db.collection('donations');

  // ─── Cases ───────────────────────────────────────────────────────────────

  Stream<List<CampaignModel>> getCampaigns({
    CampaignCategory? category,
    UrgencyLevel? urgency,
    String? organizationId,
    CampaignStatus? status,
    int limit = 20,
  }) {
    Query query = _cases;

    if (organizationId != null) {
      // Org sees all their own cases
      query = query.where('needyUserId', isEqualTo: organizationId);
    } else {
      // Donor feed: only regular campaigns (kafala cases use 'available' status)
      query = query.where('status', whereIn: ['verified', 'inProgress']);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (urgency != null) {
      query = query.where('urgencyLevel', isEqualTo: urgency.name);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CampaignModel.fromFirestore(d)).toList());
  }

  Stream<List<CampaignModel>> getFeaturedCampaigns() {
    return _cases
        .where('status', whereIn: ['verified', 'inProgress'])
        .orderBy('followersCount', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CampaignModel.fromFirestore(d))
            // Exclude kafala cases from the regular cases section
            .where((c) => c.kafalaType == null)
            .toList());
  }

  Stream<List<CampaignModel>> getUrgentCampaigns() {
    return _cases
        .where('status', whereIn: ['verified', 'inProgress'])
        .where('urgencyLevel', isEqualTo: 'high')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CampaignModel.fromFirestore(d)).toList());
  }

  Future<CampaignModel?> getCampaignById(String id) async {
    final doc = await _cases.doc(id).get();
    if (!doc.exists) return null;
    return CampaignModel.fromFirestore(doc);
  }

  Stream<CampaignModel?> watchCampaign(String id) {
    return _cases
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? CampaignModel.fromFirestore(doc) : null);
  }

  Future<String> addCampaign(CampaignModel caseModel) async {
    final ref = await _cases.add(caseModel.toFirestore());
    return ref.id;
  }

  Future<void> updateCampaign(String id, Map<String, dynamic> data) async {
    await _cases.doc(id).update({
      ...data,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteCampaign(String id) async {
    await _cases.doc(id).delete();
  }

  Future<List<CampaignModel>> searchCampaigns(String query) async {
    final lower = query.toLowerCase();
    final snap = await _cases
        .where('status', whereIn: ['verified', 'inProgress'])
        .orderBy('title')
        .startAt([lower])
        .endAt(['$lower'])
        .limit(20)
        .get();
    return snap.docs.map((d) => CampaignModel.fromFirestore(d)).toList();
  }

  // ─── Kafala Cases ─────────────────────────────────────────────────────────

  Stream<List<CampaignModel>> getKafalaCases({KafalaType? kafalaType}) {
    // Only show 'available' cases — sponsored cases are already taken
    // and should not appear in the donor's kafala feed.
    Query query;

    if (kafalaType != null) {
      query = _cases
          .where('kafalaType', isEqualTo: kafalaType.name)
          .where('status', isEqualTo: 'available');
    } else {
      query = _cases.where('status', isEqualTo: 'available');
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CampaignModel.fromFirestore(d)).toList());
  }

  Stream<UserModel?> watchUserDocument(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ─── Saved Cases ──────────────────────────────────────────────────────────

  Future<void> saveCampaign(String userId, String caseId) async {
    await _users.doc(userId).update({
      'savedCases': FieldValue.arrayUnion([caseId]),
    });
  }

  Future<void> unsaveCampaign(String userId, String caseId) async {
    await _users.doc(userId).update({
      'savedCases': FieldValue.arrayRemove([caseId]),
    });
  }

  Future<List<CampaignModel>> getSavedCampaigns(List<String> caseIds) async {
    if (caseIds.isEmpty) return [];
    final futures = caseIds.map((id) => getCampaignById(id));
    final results = await Future.wait(futures);
    return results.whereType<CampaignModel>().toList();
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _notifications.add(notification.toFirestore());
  }

  Future<void> sendInAppNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? campaignId,
    String? requestId,
  }) async {
    final notif = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      campaignId: campaignId,
      requestId: requestId,
      createdAt: DateTime.now(),
    );
    await _notifications.add(notif.toFirestore());
  }

  Future<void> incrementFollowersCount(String campaignId) async {
    await _cases.doc(campaignId).update({
      'followersCount': FieldValue.increment(1),
    });
  }

  // ─── Follows (replaces donor_requests) ───────────────────────────────────

  Future<String> createDonorRequest(DonorRequestModel request) async {
    final ref = await _follows.add(request.toFirestore());
    return ref.id;
  }

  Stream<List<DonorRequestModel>> getDonorRequests(String donorId) {
    return _follows
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DonorRequestModel.fromFirestore(d)).toList());
  }

  Stream<List<DonorRequestModel>> getOrgRequests(String needyUserId) {
    return _follows
        .where('organizationId', isEqualTo: needyUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DonorRequestModel.fromFirestore(d)).toList());
  }

  Future<void> updateRequestStatus(
      String requestId, RequestStatus status, String? note) async {
    await _follows.doc(requestId).update({
      'status': status.name,
      'organizationNote': note,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ─── Needy User Stats ─────────────────────────────────────────────────────

  Future<Map<String, int>> getOrgStats(String needyUserId) async {
    final all = await _cases
        .where('needyUserId', isEqualTo: needyUserId)
        .get();

    final verified = all.docs
        .where((d) => (d.data() as Map)['status'] == 'verified')
        .length;
    final inProgress = all.docs
        .where((d) => (d.data() as Map)['status'] == 'inProgress')
        .length;
    final resolved = all.docs
        .where((d) => (d.data() as Map)['status'] == 'resolved')
        .length;
    final pending = all.docs
        .where((d) => (d.data() as Map)['status'] == 'pending')
        .length;
    final available = all.docs
        .where((d) => (d.data() as Map)['status'] == 'available')
        .length;
    final sponsored = all.docs
        .where((d) => (d.data() as Map)['status'] == 'sponsored')
        .length;

    final pendingFollows = await _follows
        .where('organizationId', isEqualTo: needyUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    return {
      'total': all.docs.length,
      'active': verified + inProgress,
      'completed': resolved,
      'pending': pending,
      'pendingRequests': pendingFollows.docs.length,
      'available': available,
      'sponsored': sponsored,
    };
  }

  // ─── Case Updates ─────────────────────────────────────────────────────────

  /// Appends a new update entry to a campaign's updates array.
  Future<void> addCampaignUpdate(
      String campaignId, String content, String? imageUrl) async {
    final update = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
    await _cases.doc(campaignId).update({
      'updates': FieldValue.arrayUnion([update]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Approves a follow request: adds campaign to donor's followedCases,
  /// and for kafala sets status to sponsored + sponsorId/Name.
  Future<void> approveCampaignFollow({
    required String campaignId,
    required String donorId,
    required String donorName,
  }) async {
    await _users.doc(donorId).update({
      'followedCases': FieldValue.arrayUnion([campaignId]),
    });

    final campaign = await getCampaignById(campaignId);
    if (campaign != null && campaign.isKafala) {
      await _cases.doc(campaignId).update({
        'status': CampaignStatus.sponsored.name,
        'sponsorId': donorId,
        'sponsorName': donorName,
        'followersCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      await _cases.doc(campaignId).update({
        'followersCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  // ─── Donations & Kafala Payments ─────────────────────────────────────────

  /// Records a campaign donation: saves to donations collection + increments collectedAmount.
  Future<void> recordDonation(DonationRecord record) async {
    final batch = _db.batch();

    final donationRef = _donations.doc();
    batch.set(donationRef, record.toFirestore());

    final caseRef = _cases.doc(record.campaignId);
    batch.update(caseRef, {
      'collectedAmount': FieldValue.increment(record.amount),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  /// Records a kafala monthly payment: saves record + sends in-app notification to donor.
  Future<void> recordKafalaPayment(DonationRecord record) async {
    final batch = _db.batch();

    final donationRef = _donations.doc();
    batch.set(donationRef, record.toFirestore());

    await batch.commit();

    await sendInAppNotification(
      userId: record.donorId,
      title: 'تم تسجيل دفعة كفالة ✅',
      body:
          'تم تسجيل تبرعك بمبلغ ${record.amount.toStringAsFixed(0)} ريال لكفالة "${record.needyName ?? record.campaignTitle}" - ${record.orgName}',
      type: NotificationType.general,
      campaignId: record.campaignId,
    );
  }

  /// Stream of all donation records for a specific donor (campaigns + kafala).
  Stream<List<DonationRecord>> getDonorDonations(String donorId) {
    return _donations
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DonationRecord.fromFirestore(d)).toList());
  }

  // ─── User Profile ─────────────────────────────────────────────────────────

  Stream<UserModel?> watchUser(String userId) {
    return _users
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}
