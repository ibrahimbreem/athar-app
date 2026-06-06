import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/donor_request_model.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/org_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OrgDashboardScreen extends ConsumerWidget {
  const OrgDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(orgStatsProvider);
    final requests = ref.watch(orgRequestsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final orgName = user?.displayName ?? 'المنظمة';

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAF8),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orgStatsProvider);
          ref.invalidate(orgCampaignsProvider);
          ref.invalidate(orgRequestsProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ─────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor:
                  isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              scrolledUnderElevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              leading: IconButton(
                icon: Icon(Icons.menu_rounded,
                    color: isDark ? Colors.white70 : AppColors.grey600),
                onPressed: () {},
              ),
              title: Column(
                children: [
                  Text(
                    'لوحة التحكم',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'مرحباً، $orgName',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => context.go('/org/settings'),
                  icon: Icon(Icons.settings_outlined,
                      color: isDark ? Colors.white70 : AppColors.grey600),
                ),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ─── Stats ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظرة عامة',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    stats.when(
                      data: (s) => Row(
                        children: [
                          _StatCard(
                            value: '${s['total'] ?? 0}',
                            label: 'إجمالي\nالحالات',
                            color: AppColors.primary,
                            index: 0,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            value: '${s['sponsored'] ?? 0}',
                            label: 'الحالات\nالمكفولة',
                            color: AppColors.success,
                            index: 1,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            value: '${s['available'] ?? 0}',
                            label: 'المتاحة',
                            color: AppColors.info,
                            index: 2,
                          ),
                        ],
                      ),
                      loading: () => Row(
                        children: [
                          Expanded(child: const StatCardSkeleton()),
                          const SizedBox(width: 10),
                          Expanded(child: const StatCardSkeleton()),
                          const SizedBox(width: 10),
                          Expanded(child: const StatCardSkeleton()),
                        ],
                      ),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Quick Actions ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإجراءات السريعة',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2D3748)
                              : AppColors.grey100,
                        ),
                      ),
                      child: Column(
                        children: [
                          _QuickAction(
                            icon: Icons.cases_outlined,
                            label: 'إدارة الحالات',
                            onTap: () => context.go('/org/campaigns'),
                          ),
                          _QDivider(),
                          _QuickAction(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'إضافة حالة جديدة',
                            onTap: () =>
                                context.push('/org/campaign/add'),
                            isHighlighted: true,
                          ),
                          _QDivider(),
                          _QuickAction(
                            icon: Icons.update_rounded,
                            label: 'التحديثات',
                            onTap: () => context.go('/org/updates'),
                          ),
                          _QDivider(),
                          _QuickAction(
                            icon: Icons.message_outlined,
                            label: 'الرسائل والطلبات',
                            badge: requests.maybeWhen(
                              data: (list) => list
                                  .where((r) =>
                                      r.status == RequestStatus.pending)
                                  .length,
                              orElse: () => 0,
                            ),
                            onTap: () => context.go('/org/requests'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Recent Requests ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'طلبات المتابعة الأخيرة',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/org/requests'),
                      child: const Text(AppStrings.viewAll),
                    ),
                  ],
                ),
              ),
            ),
            requests.when(
              data: (list) {
                final recent = list.take(4).toList();
                if (recent.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
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
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RequestTile(
                            request: recent[i], index: i),
                      ),
                      childCount: recent.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
                ),
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

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.index,
  });
  final String value;
  final String label;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
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
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.grey500),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9));
  }
}

// ─── Quick Action ──────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
    this.badge = 0,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted ? AppColors.primary : AppColors.grey600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppColors.primaryContainer
                    : AppColors.grey50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? AppColors.primaryDark : null,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_left_rounded,
                  color: AppColors.grey300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _QDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 68);
}

// ─── Request Tile ──────────────────────────────────────────────────────────

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
            ? AppColors.warning.withValues(alpha: 0.06)
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
            backgroundColor: isPending
                ? AppColors.warning.withValues(alpha: 0.15)
                : AppColors.grey100,
            child: Text(
              request.donorName.isNotEmpty ? request.donorName[0] : 'م',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isPending ? AppColors.warning : AppColors.grey500,
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
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
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
