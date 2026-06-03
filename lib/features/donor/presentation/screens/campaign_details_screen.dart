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
        final isFollowing =
            user?.followedCases.contains(campaign.id) ?? false;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ─── Hero Image ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: Colors.black87),
                  ),
                ),
                title: const Text(
                  'تفاصيل الحالة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
                centerTitle: true,
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
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                        color:
                            isSaved ? AppColors.primary : Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Share.share(
                      'تعرف على حالة "${campaign.title}" على منصة أثر',
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(
                          left: 8, top: 8, bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
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
                              color: Colors.white.withValues(alpha: 0.5),
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
                      // Name + age + type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campaign.needyName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (campaign.kafalaType != null) ...[
                                      Text(
                                        campaign.kafalaTypeLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                      if (campaign.personAge != null)
                                        const Text(
                                          ' • ',
                                          style: TextStyle(
                                              color: AppColors.grey400),
                                        ),
                                    ],
                                    if (campaign.personAge != null)
                                      Text(
                                        '${campaign.personAge} سنوات',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _StatusChip(campaign: campaign),
                        ],
                      ),

                      // ─── "أنت تكفل هذا" banner ────────────────────
                      if (isFollowing) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      campaign.isKafala
                                          ? 'أنت تكفل هذا الطفل'
                                          : 'أنت تتابع هذه الحالة',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'شكراً لك، دعمك يصنع فرقاً في حياته',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ─── Info Card ────────────────────────────────
                      _InfoCard(campaign: campaign),

                      const SizedBox(height: 20),

                      // ─── Description ─────────────────────────────
                      Text(
                        'عن الحالة',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        campaign.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.8, color: AppColors.grey600),
                      ),

                      // ─── Needs ───────────────────────────────────
                      if (campaign.needs != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.caseNeeds,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            campaign.needs!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.6),
                          ),
                        ),
                      ],

                      // ─── Updates Timeline ─────────────────────────
                      if (campaign.updates.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.caseUpdates,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${campaign.updates.length} تحديث',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...campaign.updates
                            .map((u) => _UpdateItem(update: u)),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: (user != null && user.isDonor)
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: isFollowing
                        ? AppButton(
                            label: 'إرسال رسالة',
                            onPressed: () {},
                            icon: Icons.chat_bubble_outline_rounded,
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppButton(
                                label: campaign.isKafala
                                    ? AppStrings.sponsorNow
                                    : AppStrings.followCase,
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

// ─── Info Card ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.campaign});
  final CampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rows = <(IconData, String, String)>[
      if (campaign.location != null)
        (Icons.location_on_outlined, 'الموقع', campaign.location!),
      if (campaign.kafalaType != null)
        (Icons.category_outlined, 'نوع الحالة', campaign.kafalaTypeLabel),
      (Icons.people_outline, 'المتابعون',
          '${campaign.followersCount} متابع'),
      (Icons.flag_outlined, 'الحالة', campaign.statusLabel),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
        ),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, label, value) = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(label, style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, indent: 44),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Status Chip ───────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.campaign});
  final CampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (campaign.status) {
      case CampaignStatus.sponsored:
        color = AppColors.success;
        icon = Icons.verified_rounded;
        break;
      case CampaignStatus.inProgress:
        color = AppColors.info;
        icon = Icons.play_circle_rounded;
        break;
      case CampaignStatus.resolved:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case CampaignStatus.available:
        color = AppColors.primary;
        icon = Icons.favorite_outline_rounded;
        break;
      default:
        color = AppColors.warning;
        icon = Icons.pending_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            campaign.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Update Item ───────────────────────────────────────────────────────────

class _UpdateItem extends StatelessWidget {
  const _UpdateItem({required this.update});
  final CampaignUpdate update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (update.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: CachedNetworkImage(
                  imageUrl: update.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.content,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(update.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, duration: 300.ms);
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    return 'منذ قليل';
  }
}
