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
    this.width = 190,
  });

  final CampaignModel campaign;
  final int index;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/campaign/${campaign.id}'),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
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
                    campaign.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    campaign.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Org name
                  if (campaign.orgName.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.account_balance_outlined,
                            size: 11, color: AppColors.grey400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            campaign.orgName,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.grey500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  // Monthly amount
                  if (campaign.monthlyAmount != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${campaign.monthlyAmount!.toStringAsFixed(0)} ريال / شهر',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 11, color: AppColors.grey400),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'يتم تحديد القيمة بالتواصل مع الجمعية',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.grey400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: campaign.isSponsored
                          ? null
                          : () => context.push('/campaign/${campaign.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.grey200,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: AppColors.grey500,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        campaign.isSponsored ? 'مكفول' : 'اكفل الآن',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
        .slideX(begin: 0.15, end: 0, duration: 400.ms);
  }

  Widget _buildPhoto() {
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          campaign.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: campaign.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.primaryContainer),
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
          if (campaign.kafalaType != null && !campaign.isSponsored)
            Positioned(
              top: 10,
              right: 10,
              child: _TypeBadge(
                label: campaign.kafalaTypeLabel,
                color: _typeColor,
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

  Color get _typeColor {
    switch (campaign.kafalaType) {
      case KafalaType.orphan:
        return const Color(0xFF10B981);
      case KafalaType.universityStudent:
        return const Color(0xFF3B82F6);
      case KafalaType.needyFamily:
        return const Color(0xFFF59E0B);
      case KafalaType.patient:
        return const Color(0xFFEF4444);
      case null:
        return AppColors.primary;
    }
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (campaign.kafalaType != null)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              campaign.kafalaTypeLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        _StatusBadge(isSponsored: campaign.isSponsored),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      campaign.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (campaign.personAge != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${campaign.personAge} سنة',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (campaign.location != null) ...[
                      const SizedBox(height: 4),
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
                    if (campaign.monthlyAmount != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${campaign.monthlyAmount!.toStringAsFixed(0)} ريال / شهر',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                    if (campaign.orgName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_outlined,
                              size: 11, color: AppColors.grey400),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              campaign.orgName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.grey500,
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
