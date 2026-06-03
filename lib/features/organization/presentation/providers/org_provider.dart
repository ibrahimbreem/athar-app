import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/campaign_model.dart';
import '../../../../models/donation_record_model.dart';
import '../../../../models/donor_request_model.dart';
import '../../../../models/notification_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'dart:io';

final _firestore = FirestoreService();
final _storage = StorageService();

// ─── Needy User Cases ─────────────────────────────────────────────────────────

final orgCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return _firestore.getCampaigns(organizationId: user.id);
});

// Alias used by screens that want a consistent "cases" name
final orgCasesProvider = orgCampaignsProvider;

// ─── Stats ────────────────────────────────────────────────────────────────────

final orgStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  return _firestore.getOrgStats(user.id);
});

// ─── Follow Requests ──────────────────────────────────────────────────────────

final orgRequestsProvider = StreamProvider<List<DonorRequestModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return _firestore.getOrgRequests(user.id);
});

// ─── Case Form ────────────────────────────────────────────────────────────────

class CampaignFormState {
  final bool isLoading;
  final String? error;
  final bool success;
  final double uploadProgress;

  const CampaignFormState({
    this.isLoading = false,
    this.error,
    this.success = false,
    this.uploadProgress = 0,
  });

  CampaignFormState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    double? uploadProgress,
  }) {
    return CampaignFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

final campaignFormProvider =
    StateNotifierProvider<CampaignFormNotifier, CampaignFormState>(
  (ref) => CampaignFormNotifier(ref),
);

class CampaignFormNotifier extends StateNotifier<CampaignFormState> {
  CampaignFormNotifier(this._ref) : super(const CampaignFormState());
  final Ref _ref;

  Future<bool> addCampaign({
    required String title,
    required String description,
    required CampaignCategory category,
    required UrgencyLevel urgencyLevel,
    String? needs,
    String? location,
    List<File> images = const [],
    KafalaType? kafalaType,
    int? personAge,
    String? personName,
    double? goalAmount,
    double? monthlyAmount,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _storage.uploadMultipleImages(
          images,
          user.id,
          onProgress: (p) => state = state.copyWith(uploadProgress: p),
        );
      }

      // Kafala cases → available; regular cases → verified (visible immediately)
      final isKafala = kafalaType != null;
      final initialStatus =
          isKafala ? CampaignStatus.available : CampaignStatus.verified;

      final campaign = CampaignModel(
        id: '',
        needyUserId: user.id,
        orgName: user.displayName,
        // For kafala, needyName is the person; for campaigns it's the org
        needyName: (isKafala && personName != null && personName.trim().isNotEmpty)
            ? personName.trim()
            : user.displayName,
        needyPhotoUrl: user.photoUrl,
        isVerified: user.isVerified,
        title: title,
        description: description,
        needs: needs,
        location: location,
        category: category,
        urgencyLevel: urgencyLevel,
        imageUrls: imageUrls,
        status: initialStatus,
        kafalaType: kafalaType,
        personAge: personAge,
        goalAmount: goalAmount,
        monthlyAmount: monthlyAmount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.addCampaign(campaign);
      state = const CampaignFormState(success: true);
      return true;
    } catch (e) {
      state = CampaignFormState(error: e.toString());
      return false;
    }
  }

  Future<bool> updateCampaign(
    String campaignId,
    Map<String, dynamic> data,
    List<File> newImages,
    List<String> existingImageUrls,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      List<String> newUrls = [];
      if (newImages.isNotEmpty) {
        newUrls = await _storage.uploadMultipleImages(
          newImages,
          user.id,
          onProgress: (p) => state = state.copyWith(uploadProgress: p),
        );
      }

      await _firestore.updateCampaign(campaignId, {
        ...data,
        'imageUrls': [...existingImageUrls, ...newUrls],
      });

      state = const CampaignFormState(success: true);
      return true;
    } catch (e) {
      state = CampaignFormState(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCampaign(String campaignId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.deleteCampaign(campaignId);
      state = const CampaignFormState(success: true);
      return true;
    } catch (e) {
      state = CampaignFormState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const CampaignFormState();
}

// ─── Record Donation / Kafala Payment ────────────────────────────────────────

final recordDonationProvider =
    StateNotifierProvider<RecordDonationNotifier, AsyncValue<void>>(
  (ref) => RecordDonationNotifier(ref),
);

class RecordDonationNotifier extends StateNotifier<AsyncValue<void>> {
  RecordDonationNotifier(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  /// Records a campaign donation (increments collectedAmount).
  Future<bool> recordCampaignDonation({
    required CampaignModel campaign,
    required String donorName,
    required double amount,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final org = _ref.read(currentUserProvider);
      if (org == null) throw Exception('غير مسجل الدخول');

      final record = DonationRecord(
        id: '',
        type: DonationType.campaign,
        campaignId: campaign.id,
        campaignTitle: campaign.title,
        needyName: campaign.needyName,
        donorId: '',
        donorName: donorName,
        organizationId: org.id,
        orgName: org.displayName,
        amount: amount,
        createdAt: DateTime.now(),
        note: note,
      );

      await _firestore.recordDonation(record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  /// Records a kafala monthly payment and notifies the sponsor.
  Future<bool> recordKafalaPayment({
    required CampaignModel campaign,
    required double amount,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final org = _ref.read(currentUserProvider);
      if (org == null) throw Exception('غير مسجل الدخول');
      if (campaign.sponsorId == null) throw Exception('لا يوجد كفيل مرتبط');

      final record = DonationRecord(
        id: '',
        type: DonationType.kafala,
        campaignId: campaign.id,
        campaignTitle: campaign.title,
        needyName: campaign.needyName,
        donorId: campaign.sponsorId!,
        donorName: campaign.sponsorName ?? '',
        organizationId: org.id,
        orgName: org.displayName,
        amount: amount,
        createdAt: DateTime.now(),
        note: note,
      );

      await _firestore.recordKafalaPayment(record);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

// ─── Case Update ─────────────────────────────────────────────────────────────

final addCaseUpdateProvider =
    StateNotifierProvider.autoDispose<AddCaseUpdateNotifier, AsyncValue<void>>(
  (ref) => AddCaseUpdateNotifier(ref),
);

class AddCaseUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  AddCaseUpdateNotifier(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> addUpdate({
    required String campaignId,
    required String content,
    File? imageFile,
    String? sponsorId,
    String? campaignTitle,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('غير مسجل الدخول');

      String? imageUrl;
      if (imageFile != null) {
        final urls = await _storage.uploadMultipleImages([imageFile], user.id);
        if (urls.isNotEmpty) imageUrl = urls.first;
      }

      await _firestore.addCampaignUpdate(campaignId, content, imageUrl);

      if (sponsorId != null && campaignTitle != null) {
        await _firestore.sendInAppNotification(
          userId: sponsorId,
          title: 'تحديث جديد على الحالة 📸',
          body: 'تم نشر تحديث جديد على حالة "$campaignTitle"',
          type: NotificationType.campaignUpdate,
          campaignId: campaignId,
        );
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

// ─── Follow Request Actions ───────────────────────────────────────────────────

final requestActionsProvider =
    StateNotifierProvider<RequestActionsNotifier, AsyncValue<void>>(
  (ref) => RequestActionsNotifier(),
);

class RequestActionsNotifier extends StateNotifier<AsyncValue<void>> {
  RequestActionsNotifier() : super(const AsyncValue.data(null));

  Future<void> updateStatus(
    String requestId,
    RequestStatus status,
    String? note,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _firestore.updateRequestStatus(requestId, status, note);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
