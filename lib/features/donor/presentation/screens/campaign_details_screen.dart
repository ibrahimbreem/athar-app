import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/campaign_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/campaigns_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CampaignDetailsScreen extends ConsumerWidget {
  const CampaignDetailsScreen({super.key, required this.campaignId});
  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignByIdProvider(campaignId));
    final actions = ref.watch(campaignActionsProvider.notifier);
    final user = ref.watch(currentUserProvider);

    return campaignAsync.when(
      data: (campaign) {
        if (campaign == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('الحالة غير موجودة')),
          );
        }
        final isSaved = actions.isSaved(campaign.id);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ─── Hero Image ─────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: Colors.black87),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => actions.toggleSave(campaign.id),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                        color: isSaved ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Share.share(
                      'تعرف على حالة "${campaign.title}" على منصة أثر',
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.share_outlined,
                          size: 20, color: Colors.black87),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: campaign.imageUrls.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: campaign.imageUrls.first,
                              fit: BoxFit.cover,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.overlayGradient,
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.heroGradient,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.cases_rounded,
                              size: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                ),
              ),

              // ─── Content ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Needy person row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryContainer,
                            backgroundImage: campaign.needyPhotoUrl != null
                                ? CachedNetworkImageProvider(
                                    campaign.needyPhotoUrl!)
                                : null,
                            child: campaign.needyPhotoUrl == null
                                ? Text(
                                    campaign.needyName.isNotEmpty
                                        ? campaign.needyName[0]
                                        : 'م',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              campaign.needyName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (campaign.isVerified)
                            Row(
                              children: const [
                                Icon(Icons.verified,
                                    size: 16, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  AppStrings.verified,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(width: 8),
                          _UrgencyChip(level: campaign.urgencyLevel),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        campaign.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ).animate().fadeIn().slideY(begin: 0.2),

                      const SizedBox(height: 20),

                      // Status Card
                      _StatusCard(campaign: campaign),

                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'عن الحالة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        campaign.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.8,
                            ),
                      ),

                      // Needs
                      if (campaign.needs != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.caseNeeds,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            campaign.needs!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(height: 1.6),
                          ),
                        ),
                      ],

                      // Info rows
                      const SizedBox(height: 16),
                      if (campaign.location != null)
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: AppStrings.caseLocation,
                          value: campaign.location!,
                        ),
                      _InfoRow(
                        icon: Icons.people_outline,
                        label: 'المتابعون',
                        value: '${campaign.followersCount} متابع',
                      ),
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: 'التصنيف',
                        value: campaign.categoryLabel,
                      ),

                      // Updates timeline
                      if (campaign.updates.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          AppStrings.caseUpdates,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        ...campaign.updates.map((u) => _UpdateItem(update: u)),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: user != null
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton(
                          label: AppStrings.followCase,
                          onPressed: campaign.isCompleted
                              ? null
                              : () => context.push(
                                  '/campaign/${campaign.id}/intent'),
                          icon: Icons.favorite_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: AppStrings.contactNeedy,
                          onPressed: () {},
                          variant: ButtonVariant.outlined,
                          icon: Icons.chat_bubble_outline_rounded,
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const CampaignsSkeletonList(count: 1),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.campaign});
  final CampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    switch (campaign.status) {
      case CampaignStatus.verified:
        statusColor = AppColors.primary;
        break;
      case CampaignStatus.inProgress:
        statusColor = AppColors.info;
        break;
      case CampaignStatus.resolved:
        statusColor = AppColors.success;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? const Color(0xFF2D3748) : AppColors.grey100),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline_rounded, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الطلب',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  campaign.statusLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.people_outline, size: 16, color: AppColors.grey400),
              const SizedBox(height: 2),
              Text(
                '${campaign.followersCount}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('متابع', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip({required this.level});
  final UrgencyLevel level;

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (level) {
      case UrgencyLevel.high:
        bg = AppColors.urgencyHigh;
        label = 'عاجل';
        break;
      case UrgencyLevel.medium:
        bg = AppColors.urgencyMedium;
        label = 'متوسط';
        break;
      case UrgencyLevel.low:
        bg = AppColors.urgencyLow;
        label = 'عادي';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UpdateItem extends StatelessWidget {
  const _UpdateItem({required this.update});
  final CampaignUpdate update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 60, color: AppColors.grey200),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                update.content,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(update.createdAt),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    return 'منذ قليل';
  }
}
