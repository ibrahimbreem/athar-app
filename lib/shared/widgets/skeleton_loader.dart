import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
      highlightColor: isDark ? const Color(0xFF3D4758) : AppColors.grey50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D3748) : AppColors.grey200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CampaignCardSkeleton extends StatelessWidget {
  const CampaignCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
        ),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 86, height: 86, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                SkeletonBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 12),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    SkeletonBox(width: 60, height: 22, borderRadius: 10),
                    SizedBox(width: 8),
                    SkeletonBox(width: 50, height: 12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 58, height: 58, borderRadius: 29),
        ],
      ),
    );
  }
}

class CampaignsSkeletonList extends StatelessWidget {
  const CampaignsSkeletonList({super.key, this.count = 3});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.p16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.gap16),
      itemBuilder: (_, __) => const CampaignCardSkeleton(),
    );
  }
}

class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 32, height: 32, borderRadius: 8),
          SizedBox(height: 12),
          SkeletonBox(width: 60, height: 24),
          SizedBox(height: 6),
          SkeletonBox(width: 80, height: 12),
        ],
      ),
    );
  }
}
