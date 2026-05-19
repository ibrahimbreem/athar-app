import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/donor_request_model.dart';
import '../../../../shared/widgets/campaign_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/org_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OrgDashboardScreen extends ConsumerWidget {
  const OrgDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(orgStatsProvider);
    final campaigns = ref.watch(orgCampaignsProvider);
    final requests = ref.watch(orgRequestsProvider);
    final theme = Theme.of(context);

    final orgName = user?.displayName ?? 'المنظمة';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orgStatsProvider);
          ref.invalidate(orgCampaignsProvider);
          ref.invalidate(orgRequestsProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ─── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            orgName.isNotEmpty ? orgName[0] : 'م',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مرحباً بك،',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                              Text(
                                orgName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (user?.isVerified == true)
                                Row(
                                  children: const [
                                    Icon(Icons.verified,
                                        size: 14, color: Colors.white70),
                                    SizedBox(width: 4),
                                    Text(
                                      AppStrings.verifiedOrg,
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.go('/org/settings'),
                          icon: const Icon(Icons.settings_outlined,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Stats Grid ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: stats.when(
                  data: (s) => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(
                        icon: Icons.cases_outlined,
                        label: AppStrings.totalCases,
                        value: '${s['total'] ?? 0}',
                        color: AppColors.primary,
                        index: 0,
                      ),
                      _StatCard(
                        icon: Icons.play_circle_outline_rounded,
                        label: AppStrings.activeCases,
                        value: '${s['active'] ?? 0}',
                        color: AppColors.info,
                        index: 1,
                      ),
                      _StatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: AppStrings.resolvedCases,
                        value: '${s['completed'] ?? 0}',
                        color: AppColors.success,
                        index: 2,
                      ),
                      _StatCard(
                        icon: Icons.pending_outlined,
                        label: AppStrings.pendingFollows,
                        value: '${s['pendingRequests'] ?? 0}',
                        color: AppColors.warning,
                        index: 3,
                      ),
                    ],
                  ),
                  loading: () => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: List.generate(
                        4, (_) => const StatCardSkeleton()),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),

            // ─── Quick Add ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/org/campaign/add'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.addCase),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // ─── Recent Requests ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  children: [
                    Text(
                      'طلبات المتابعة الأخيرة',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    requests.when(
                      data: (list) {
                        final pending = list
                            .where(
                                (r) => r.status == RequestStatus.pending)
                            .length;
                        if (pending > 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$pending جديد',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
            requests.when(
              data: (list) => list.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.inbox_outlined,
                                  color: AppColors.grey400),
                              SizedBox(width: 12),
                              Text(
                                'لا توجد طلبات متابعة حتى الآن',
                                style: TextStyle(color: AppColors.grey500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RequestTile(
                              request: list[i],
                              index: i,
                            ),
                          ),
                          childCount: list.take(5).length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            ),

            // ─── My Campaigns ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  children: [
                    Text(
                      'حالاتي',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/org/campaigns'),
                      child: const Text(AppStrings.viewAll),
                    ),
                  ],
                ),
              ),
            ),
            campaigns.when(
              data: (list) => list.isEmpty
                  ? SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.cases_outlined,
                        title: AppStrings.noCampaigns,
                        description: AppStrings.noCampaignsDesc,
                        action: () =>
                            context.push('/org/campaign/add'),
                        actionLabel: AppStrings.addCase,
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: CampaignCard(
                              campaign: list[i],
                              index: i,
                            ),
                          ),
                          childCount: list.take(3).length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(
                child: CampaignsSkeletonList(count: 2),
              ),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.index,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.index});
  final DonorRequestModel request;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPending = request.status == RequestStatus.pending;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending
            ? AppColors.warning.withValues(alpha: 0.08)
            : (isDark ? AppColors.surfaceDark : AppColors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF2D3748) : AppColors.grey100),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                isPending ? AppColors.warning.withValues(alpha: 0.15) : AppColors.grey100,
            child: Text(
              request.donorName.isNotEmpty ? request.donorName[0] : 'م',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPending ? AppColors.warning : AppColors.grey500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.donorName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  request.campaignTitle,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(request.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              request.statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor(request.status),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 300.ms);
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return AppColors.warning;
      case RequestStatus.approved:
        return AppColors.success;
      case RequestStatus.rejected:
        return AppColors.error;
      case RequestStatus.reviewed:
        return AppColors.info;
    }
  }
}
