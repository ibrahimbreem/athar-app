import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../models/donor_request_model.dart';
import '../../../../models/notification_model.dart';
import '../../../../services/firebase_auth_service.dart';
import '../../../../services/firestore_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/campaigns_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DonationIntentScreen extends ConsumerStatefulWidget {
  const DonationIntentScreen({super.key, required this.campaignId});
  final String campaignId;

  @override
  ConsumerState<DonationIntentScreen> createState() =>
      _DonationIntentScreenState();
}

class _DonationIntentScreenState extends ConsumerState<DonationIntentScreen> {
  final _messageCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String caseTitle, String needyUserId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final request = DonorRequestModel(
        id: '',
        donorId: user.id,
        donorName: user.fullName,
        donorPhone: user.phone,
        donorEmail: user.email,
        campaignId: widget.campaignId,
        campaignTitle: caseTitle,
        organizationId: needyUserId,
        message: _messageCtrl.text.trim().isEmpty
            ? null
            : _messageCtrl.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final requestId = await FirestoreService().createDonorRequest(request);

      // Notify the organization
      await FirestoreService().sendInAppNotification(
        userId: needyUserId,
        title: 'طلب متابعة جديد 🤝',
        body: 'أبدى ${user.fullName} اهتماماً بحالة "$caseTitle"',
        type: NotificationType.donationRequest,
        campaignId: widget.campaignId,
        requestId: requestId,
      );

      // Add campaign to donor's followed list
      await FirebaseAuthService().updateUserData(user.id, {
        'followedCases': FieldValue.arrayUnion([widget.campaignId]),
      });

      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaignAsync = ref.watch(campaignByIdProvider(widget.campaignId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.followTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: campaignAsync.when(
        data: (campaign) {
          if (campaign == null) {
            return const Center(child: Text('الحالة غير موجودة'));
          }

          if (_sent) {
            return _SuccessView(onBack: () => context.go('/donor/home'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Case info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cases_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              campaign.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              campaign.needyName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.surfaceDark
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: Column(
                    children: [
                      _InfoItem(
                        icon: Icons.info_outline_rounded,
                        text: AppStrings.followDesc,
                      ),
                      const Divider(height: 24),
                      _InfoItem(
                        icon: Icons.phone_outlined,
                        text: 'ستتواصل معك على: ${ref.read(currentUserProvider)?.phone ?? 'رقم الهاتف غير محدد'}',
                      ),
                      const Divider(height: 24),
                      _InfoItem(
                        icon: Icons.email_outlined,
                        text: 'أو عبر البريد: ${ref.read(currentUserProvider)?.email ?? ''}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Needy person info
                Text(
                  AppStrings.needyInfo,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _NeedyInfoCard(
                  needyName: campaign.needyName,
                  isVerified: campaign.isVerified,
                  photoUrl: campaign.needyPhotoUrl,
                ),

                const SizedBox(height: 24),

                // Optional message
                Text(
                  AppStrings.followMessage,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: AppStrings.followMessage,
                  hint: AppStrings.followMessageHint,
                  controller: _messageCtrl,
                  maxLines: 4,
                ),

                const SizedBox(height: 32),

                AppButton(
                  label: AppStrings.sendFollow,
                  onPressed: () => _send(campaign.title, campaign.needyUserId),
                  isLoading: _isLoading,
                  icon: Icons.favorite_outline_rounded,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: AppStrings.contactNow,
                  onPressed: () {},
                  variant: ButtonVariant.outlined,
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ),
      ],
    );
  }
}

class _NeedyInfoCard extends StatelessWidget {
  const _NeedyInfoCard({
    required this.needyName,
    required this.isVerified,
    this.photoUrl,
  });
  final String needyName;
  final bool isVerified;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    needyName.isNotEmpty ? needyName[0] : 'م',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      needyName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
                if (isVerified)
                  Text(
                    AppStrings.verifiedOrg,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'تمت المتابعة!',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.followSent,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'ستصلك تحديثات الحالة وسيتواصل معك صاحبها قريباً',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          AppButton(
            label: 'العودة للرئيسية',
            onPressed: onBack,
            icon: Icons.home_rounded,
          ),
        ],
      ),
    );
  }
}
