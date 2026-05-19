import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/campaign_model.dart';
import '../../../../models/donor_request_model.dart';
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
        // For kafala, use the person's name; otherwise use org name
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
