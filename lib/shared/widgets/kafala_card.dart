import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/campaign_model.dart';

class KafalaCard extends StatelessWidget {
  const KafalaCard({
    super.key,
    required this.campaign,
    this.index = 0,
    this.width = 180,
  });

  final CampaignModel campaign;
  final int index;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/campaign/${campaign.id}'),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhoto(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.needyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (campaign.personAge != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${campaign.personAge} سنة',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (campaign.kafalaType != null)
                        _TypeChip(label: campaign.kafalaTypeLabel),
                      const Spacer(),
                      _StatusBadge(isSponsored: campaign.isSponsored),
                    ],
                  ),
                  if (campaign.location != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.grey400),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            campaign.location!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.15, end: 0, duration: 400.ms);
  }

  Widget _buildPhoto() {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          campaign.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: campaign.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.primaryContainer),
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
          if (campaign.isSponsored)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: const Center(
                child: Text(
                  'مكفول ✓',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryContainer,
      child: Center(
        child: Icon(
          _typeIcon,
          size: 48,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  IconData get _typeIcon {
    switch (campaign.kafalaType) {
      case KafalaType.orphan:
        return Icons.child_care_outlined;
      case KafalaType.universityStudent:
        return Icons.school_outlined;
      case KafalaType.needyFamily:
        return Icons.family_restroom_outlined;
      case KafalaType.patient:
        return Icons.medical_services_outlined;
      case null:
        return Icons.person_outline;
    }
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isSponsored});
  final bool isSponsored;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSponsored
            ? AppColors.grey100
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isSponsored ? 'مكفول' : 'متاح',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isSponsored ? AppColors.grey500 : AppColors.primaryDark,
        ),
      ),
    );
  }
}

// Vertical list card for kafala list screen
class KafalaListCard extends StatelessWidget {
  const KafalaListCard({super.key, required this.campaign, this.index = 0});
  final CampaignModel campaign;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/campaign/${campaign.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 110,
                child: campaign.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: campaign.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primaryContainer,
                          child: const Icon(Icons.person_outline,
                              color: AppColors.primary, size: 36),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryContainer,
                        child: const Icon(Icons.person_outline,
                            color: AppColors.primary, size: 36),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.needyName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (campaign.personAge != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${campaign.personAge} سنة',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (campaign.kafalaType != null)
                      _TypeChip(label: campaign.kafalaTypeLabel),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (campaign.location != null) ...[
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.grey400),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              campaign.location!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.grey400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        _StatusBadge(isSponsored: campaign.isSponsored),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.chevron_left_rounded,
                  color: AppColors.grey300, size: 20),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0, duration: 350.ms);
  }
}
