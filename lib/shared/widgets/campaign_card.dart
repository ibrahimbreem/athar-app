import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/campaign_model.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    this.onSave,
    this.isSaved = false,
    this.index = 0,
  });

  final CampaignModel campaign;
  final VoidCallback? onSave;
  final bool isSaved;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/campaign/${campaign.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context),
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNeedyRow(context, theme),
                  const SizedBox(height: AppSizes.gap8),
                  Text(
                    campaign.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.gap8),
                  _buildStatusRow(context, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildImage(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: campaign.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: campaign.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.grey100,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _placeholderImage(),
                )
              : _placeholderImage(),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: _buildUrgencyBadge(),
        ),
        if (onSave != null)
          Positioned(
            top: 10,
            left: 10,
            child: GestureDetector(
              onTap: onSave,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  size: 18,
                  color: isSaved ? AppColors.primary : AppColors.grey500,
                ),
              ),
            ),
          ),
        if (campaign.isCompleted)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
              child: const Center(
                child: Text(
                  'تم الحل ✓',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppColors.primaryContainer,
      child: Center(
        child: Icon(
          _categoryIcon,
          size: 48,
          color: AppColors.primary.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge() {
    Color bg;
    switch (campaign.urgencyLevel) {
      case UrgencyLevel.high:
        bg = AppColors.urgencyHigh;
        break;
      case UrgencyLevel.medium:
        bg = AppColors.urgencyMedium;
        break;
      case UrgencyLevel.low:
        bg = AppColors.urgencyLow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        campaign.urgencyLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNeedyRow(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primaryContainer,
          backgroundImage: campaign.needyPhotoUrl != null
              ? CachedNetworkImageProvider(campaign.needyPhotoUrl!)
              : null,
          child: campaign.needyPhotoUrl == null
              ? Text(
                  campaign.needyName.isNotEmpty ? campaign.needyName[0] : 'م',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            campaign.needyName,
            style: theme.textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (campaign.isVerified)
          const Icon(
            Icons.verified,
            size: 14,
            color: AppColors.primary,
          ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            campaign.categoryLabel,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(BuildContext context, ThemeData theme) {
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
        statusColor = AppColors.grey400;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            campaign.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.people_outline, size: 13, color: AppColors.grey400),
            const SizedBox(width: 3),
            Text(
              '${campaign.followersCount} متابع',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData get _categoryIcon {
    switch (campaign.category) {
      case CampaignCategory.medical:
        return Icons.medical_services_outlined;
      case CampaignCategory.education:
        return Icons.school_outlined;
      case CampaignCategory.food:
        return Icons.restaurant_outlined;
      case CampaignCategory.housing:
        return Icons.home_outlined;
      case CampaignCategory.orphan:
        return Icons.child_care_outlined;
      case CampaignCategory.disaster:
        return Icons.warning_amber_outlined;
      case CampaignCategory.environment:
        return Icons.eco_outlined;
      case CampaignCategory.other:
        return Icons.volunteer_activism_outlined;
    }
  }
}

// Compact horizontal card for lists
class CampaignCardCompact extends StatelessWidget {
  const CampaignCardCompact({
    super.key,
    required this.campaign,
    this.onTap,
  });

  final CampaignModel campaign;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap ?? () => context.push('/campaign/${campaign.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 70,
                height: 70,
                child: campaign.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: campaign.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primaryContainer,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.primary),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryContainer,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.primary),
                      ),
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
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    campaign.needyName,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    campaign.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                const Icon(Icons.people_outline,
                    size: 14, color: AppColors.grey400),
                const SizedBox(height: 2),
                Text(
                  '${campaign.followersCount}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
