import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
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
    final progress = campaign.progressPercentage;
    final progressPct = (progress * 100).toInt();

    return GestureDetector(
      onTap: () => context.push('/campaign/${campaign.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 86,
                height: 86,
                child: campaign.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: campaign.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.primaryContainer),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          campaign.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onSave != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onSave,
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 18,
                            color: isSaved
                                ? AppColors.primary
                                : AppColors.grey400,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    campaign.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          campaign.statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.people_outline,
                          size: 12, color: AppColors.grey400),
                      const SizedBox(width: 3),
                      Text(
                        '${campaign.followersCount} متابع',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (campaign.goalAmount != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${campaign.collectedAmount.toStringAsFixed(0)} ر.س',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                        const Text(
                          ' / ',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.grey400,
                          ),
                        ),
                        Text(
                          '${campaign.goalAmount!.toStringAsFixed(0)} ر.س',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Progress ring
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: AppColors.grey100,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_statusColor),
                  ),
                  Center(
                    child: Text(
                      '$progressPct%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, duration: 400.ms);
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryContainer,
      child: Center(
        child: Icon(
          _categoryIcon,
          size: 32,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (campaign.status) {
      case CampaignStatus.resolved:
        return AppColors.success;
      case CampaignStatus.inProgress:
        return AppColors.info;
      case CampaignStatus.verified:
        return AppColors.primary;
      default:
        return AppColors.grey400;
    }
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

// Compact card for small contexts (org dashboard recent list, etc.)
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
                width: 60,
                height: 60,
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
