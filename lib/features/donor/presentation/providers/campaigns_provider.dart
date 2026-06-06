import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/campaign_model.dart';
import '../../../../models/donation_record_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _firestore = FirestoreService();

// ─── All Cases ────────────────────────────────────────────────────────────────

final campaignsProvider = StreamProvider.family<List<CampaignModel>,
    Map<String, dynamic>>((ref, params) {
  final category = params['category'] as CampaignCategory?;
  final urgency = params['urgency'] as UrgencyLevel?;
  return _firestore.getCampaigns(category: category, urgency: urgency);
});

final allActiveCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  return _firestore.getCampaigns();
});

final featuredCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  return _firestore.getFeaturedCampaigns();
});

final urgentCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  return _firestore.getUrgentCampaigns();
});

final campaignByIdProvider =
    StreamProvider.family<CampaignModel?, String>((ref, id) {
  return _firestore.watchCampaign(id);
});

// ─── Search ───────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.family<List<CampaignModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return _firestore.searchCampaigns(query);
});

// ─── Category Filter ──────────────────────────────────────────────────────────

final selectedCategoryProvider =
    StateProvider<CampaignCategory?>((ref) => null);

// ─── Kafala ───────────────────────────────────────────────────────────────────

final selectedKafalaTypeProvider =
    StateProvider<KafalaType?>((ref) => null);

final kafalaProvider = StreamProvider<List<CampaignModel>>((ref) {
  final type = ref.watch(selectedKafalaTypeProvider);
  return _firestore.getKafalaCases(kafalaType: type);
});

// ─── Saved Cases ──────────────────────────────────────────────────────────────

final savedCampaignsProvider =
    FutureProvider<List<CampaignModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.savedCases.isEmpty) return [];
  return _firestore.getSavedCampaigns(user.savedCases);
});

// ─── Followed Cases ───────────────────────────────────────────────────────────
// StreamProvider so that org-approved followedCases appear immediately
// without requiring the donor to re-login.

final followedCasesProvider = StreamProvider<List<CampaignModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return _firestore.watchUserDocument(user.id).asyncMap((freshUser) async {
    if (freshUser == null || freshUser.followedCases.isEmpty) {
      return <CampaignModel>[];
    }
    return _firestore.getSavedCampaigns(freshUser.followedCases);
  });
});

// ─── Save/Unsave Actions ──────────────────────────────────────────────────────

final campaignActionsProvider =
    StateNotifierProvider<CampaignActionsNotifier, AsyncValue<void>>(
  (ref) => CampaignActionsNotifier(ref),
);

class CampaignActionsNotifier extends StateNotifier<AsyncValue<void>> {
  CampaignActionsNotifier(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<void> toggleSave(String campaignId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final isSaved = user.savedCases.contains(campaignId);

    if (isSaved) {
      await _firestore.unsaveCampaign(user.id, campaignId);
      final updated = List<String>.from(user.savedCases)..remove(campaignId);
      _ref.read(currentUserProvider.notifier).updateSavedCampaigns(updated);
    } else {
      await _firestore.saveCampaign(user.id, campaignId);
      final updated = List<String>.from(user.savedCases)..add(campaignId);
      _ref.read(currentUserProvider.notifier).updateSavedCampaigns(updated);
    }
  }

  bool isSaved(String campaignId) {
    final user = _ref.read(currentUserProvider);
    return user?.savedCases.contains(campaignId) ?? false;
  }
}

// ─── Donor Donation History ───────────────────────────────────────────────────

final donorDonationsProvider = StreamProvider<List<DonationRecord>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return _firestore.getDonorDonations(user.id);
});
