import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../models/campaign_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/org_provider.dart';

class CampaignManagementScreen extends ConsumerWidget {
  const CampaignManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(orgCampaignsProvider);
    final formNotifier = ref.read(campaignFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحالات'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push('/org/campaign/add'),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: AppStrings.addCase,
          ),
        ],
      ),
      body: campaigns.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.cases_outlined,
                title: AppStrings.noCampaigns,
                description: AppStrings.noCampaignsDesc,
                action: () => context.push('/org/campaign/add'),
                actionLabel: AppStrings.addCase,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _OrgCaseTile(
                  campaign: list[i],
                  index: i,
                  onDelete: () async {
                    final confirm = await context.showConfirmDialog(
                      title: AppStrings.confirmDelete,
                      message: AppStrings.deleteConfirmMsg,
                      confirmText: AppStrings.delete,
                      isDestructive: true,
                    );
                    if (confirm == true) {
                      final ok =
                          await formNotifier.deleteCampaign(list[i].id);
                      if (context.mounted) {
                        ok
                            ? context.showSuccessSnackBar(
                                AppStrings.successCampaignDeleted)
                            : context.showErrorSnackBar(
                                AppStrings.errorGeneral);
                      }
                    }
                  },
                ),
              ),
        loading: () => const CampaignsSkeletonList(),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/org/campaign/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          AppStrings.addCase,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _OrgCaseTile extends StatelessWidget {
  const _OrgCaseTile({
    required this.campaign,
    required this.index,
    required this.onDelete,
  });

  final CampaignModel campaign;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
                  color: AppColors.primary.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _statusColor(campaign.status).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(campaign.status),
                    color: _statusColor(campaign.status),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              campaign.title,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(status: campaign.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (campaign.location != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.grey400),
                            const SizedBox(width: 3),
                            Text(
                              campaign.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${campaign.followersCount} متابع · ${campaign.categoryLabel}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () =>
                      context.push('/org/campaign/${campaign.id}/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(AppStrings.editCase),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.grey100),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text(AppStrings.deleteCase),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Color _statusColor(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.verified:
        return AppColors.primary;
      case CampaignStatus.inProgress:
        return AppColors.info;
      case CampaignStatus.resolved:
        return AppColors.success;
      case CampaignStatus.pending:
        return AppColors.warning;
      case CampaignStatus.closed:
        return AppColors.grey400;
      case CampaignStatus.available:
        return AppColors.primary;
      case CampaignStatus.sponsored:
        return AppColors.grey500;
    }
  }

  IconData _statusIcon(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.verified:
        return Icons.verified_outlined;
      case CampaignStatus.inProgress:
        return Icons.play_circle_outline_rounded;
      case CampaignStatus.resolved:
        return Icons.check_circle_outline_rounded;
      case CampaignStatus.pending:
        return Icons.pending_outlined;
      case CampaignStatus.closed:
        return Icons.cancel_outlined;
      case CampaignStatus.available:
        return Icons.favorite_outline_rounded;
      case CampaignStatus.sponsored:
        return Icons.favorite_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case CampaignStatus.verified:
        bg = AppColors.primary;
        label = 'موثقة';
        break;
      case CampaignStatus.inProgress:
        bg = AppColors.info;
        label = 'جارٍ المساعدة';
        break;
      case CampaignStatus.resolved:
        bg = AppColors.success;
        label = 'تم الحل';
        break;
      case CampaignStatus.pending:
        bg = AppColors.warning;
        label = 'قيد المراجعة';
        break;
      case CampaignStatus.closed:
        bg = AppColors.grey400;
        label = 'مغلقة';
        break;
      case CampaignStatus.available:
        bg = AppColors.primary;
        label = 'متاح للكفالة';
        break;
      case CampaignStatus.sponsored:
        bg = AppColors.grey500;
        label = 'مكفول';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: bg,
        ),
      ),
    );
  }
}
