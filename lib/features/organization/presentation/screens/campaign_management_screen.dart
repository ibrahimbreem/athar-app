import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../models/campaign_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/org_provider.dart';

class CampaignManagementScreen extends ConsumerStatefulWidget {
  const CampaignManagementScreen({super.key});

  @override
  ConsumerState<CampaignManagementScreen> createState() =>
      _CampaignManagementScreenState();
}

class _CampaignManagementScreenState
    extends ConsumerState<CampaignManagementScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();
  // null=all, false=available, true=sponsored
  bool? _filterSponsored;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(orgCampaignsProvider);
    final formNotifier = ref.read(campaignFormProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAF8),
      body: CustomScrollView(
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
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.primary),
              onPressed: () => context.push('/org/campaign/add'),
              tooltip: AppStrings.addCase,
            ),
            title: const Text(
              'إدارة الحالات',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.menu_rounded,
                    color: isDark ? Colors.white70 : AppColors.grey600),
                onPressed: () {},
              ),
            ],
          ),

          // ─── Search + Filter ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن حالة...',
                        hintStyle: const TextStyle(
                            color: AppColors.grey400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.grey400, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: AppColors.grey400),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter tabs
                  Row(
                    children: [
                      _FilterTab(
                        label: 'الكل',
                        isSelected: _filterSponsored == null,
                        onTap: () =>
                            setState(() => _filterSponsored = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'مكفول',
                        isSelected: _filterSponsored == true,
                        onTap: () =>
                            setState(() => _filterSponsored = true),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'متاح',
                        isSelected: _filterSponsored == false,
                        onTap: () =>
                            setState(() => _filterSponsored = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ─── List ────────────────────────────────────────────────
          campaigns.when(
            data: (list) {
              final filtered = _filter(list);
              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.cases_outlined,
                    title: AppStrings.noCampaigns,
                    description: AppStrings.noCampaignsDesc,
                    action: () => context.push('/org/campaign/add'),
                    actionLabel: AppStrings.addCase,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CaseTile(
                        campaign: filtered[i],
                        index: i,
                        onDelete: () async {
                          final confirm =
                              await context.showConfirmDialog(
                            title: AppStrings.confirmDelete,
                            message: AppStrings.deleteConfirmMsg,
                            confirmText: AppStrings.delete,
                            isDestructive: true,
                          );
                          if (confirm == true) {
                            final ok = await formNotifier
                                .deleteCampaign(filtered[i].id);
                            if (context.mounted) {
                              ok
                                  ? context.showSuccessSnackBar(
                                      AppStrings.successCampaignDeleted)
                                  : context.showErrorSnackBar(
                                      AppStrings.errorGeneral);
                            }
                          }
                        },
                        onRecord: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _RecordDonationSheet(
                            campaign: filtered[i],
                          ),
                        ),
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: CampaignsSkeletonList()),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }

  List<CampaignModel> _filter(List<CampaignModel> list) {
    var result = list;
    if (_filterSponsored != null) {
      result =
          result.where((c) => c.isSponsored == _filterSponsored).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      result = result
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              c.needyName.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }
}

// ─── Case Tile ─────────────────────────────────────────────────────────────

class _CaseTile extends StatelessWidget {
  const _CaseTile({
    required this.campaign,
    required this.index,
    required this.onDelete,
    required this.onRecord,
  });

  final CampaignModel campaign;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onRecord;

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
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // ─── Info row ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: campaign.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: campaign.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _placeholderThumb(),
                          )
                        : _placeholderThumb(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              campaign.needyName,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(status: campaign.status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (campaign.personAge != null)
                        Text(
                          '${campaign.kafalaTypeLabel} • ${campaign.personAge} سنوات',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (campaign.location != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.grey400),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                campaign.location!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.grey500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.favorite_outline_rounded,
                              size: 12, color: AppColors.grey400),
                          const SizedBox(width: 3),
                          Text(
                            '${campaign.followersCount} متابع',
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

          const Divider(height: 1),

          // ─── Action buttons ───────────────────────────────────────
          Row(
            children: [
              _ActionBtn(
                icon: Icons.visibility_outlined,
                label: 'عرض',
                color: AppColors.grey600,
                onTap: () =>
                    context.push('/campaign/${campaign.id}'),
              ),
              _VLine(),
              _ActionBtn(
                icon: Icons.edit_outlined,
                label: 'تعديل',
                color: AppColors.primary,
                onTap: () =>
                    context.push('/org/campaign/${campaign.id}/edit'),
              ),
              _VLine(),
              _ActionBtn(
                icon: Icons.delete_outline_rounded,
                label: 'حذف',
                color: AppColors.error,
                onTap: onDelete,
              ),
              _VLine(),
              _ActionBtn(
                icon: campaign.isKafala
                    ? Icons.payments_outlined
                    : Icons.add_circle_outline_rounded,
                label: campaign.isKafala ? 'دفعة' : 'تبرع',
                color: AppColors.success,
                onTap: onRecord,
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 70))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0);
  }

  Widget _placeholderThumb() {
    return Container(
      color: AppColors.primaryContainer,
      child: const Icon(Icons.person_outline,
          color: AppColors.primary, size: 28),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppColors.grey100);
}

// ─── Filter Tab ────────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.grey100,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case CampaignStatus.sponsored:
        color = AppColors.success;
        label = 'مكفول';
        break;
      case CampaignStatus.available:
        color = AppColors.primary;
        label = 'متاح';
        break;
      case CampaignStatus.inProgress:
        color = AppColors.info;
        label = 'جارٍ';
        break;
      case CampaignStatus.resolved:
        color = AppColors.success;
        label = 'تم الحل';
        break;
      case CampaignStatus.pending:
        color = AppColors.warning;
        label = 'مراجعة';
        break;
      default:
        color = AppColors.grey400;
        label = 'مغلق';
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Record Donation / Payment Bottom Sheet ────────────────────────────────

class _RecordDonationSheet extends ConsumerStatefulWidget {
  const _RecordDonationSheet({required this.campaign});
  final CampaignModel campaign;

  @override
  ConsumerState<_RecordDonationSheet> createState() =>
      _RecordDonationSheetState();
}

class _RecordDonationSheetState extends ConsumerState<_RecordDonationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _donorNameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.campaign.isKafala && widget.campaign.monthlyAmount != null) {
      _amountCtrl.text = widget.campaign.monthlyAmount!.toStringAsFixed(0);
    }
    if (widget.campaign.isKafala && widget.campaign.sponsorName != null) {
      _donorNameCtrl.text = widget.campaign.sponsorName!;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _donorNameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    final notifier = ref.read(recordDonationProvider.notifier);
    bool ok;

    if (widget.campaign.isKafala) {
      ok = await notifier.recordKafalaPayment(
        campaign: widget.campaign,
        amount: amount,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
    } else {
      ok = await notifier.recordCampaignDonation(
        campaign: widget.campaign,
        donorName: _donorNameCtrl.text.trim(),
        amount: amount,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.campaign.isKafala
            ? 'تم تسجيل الدفعة وإرسال إشعار للكفيل ✅'
            : 'تم تسجيل التبرع وتحديث المبلغ المجموع ✅'),
        backgroundColor: AppColors.success,
      ));
    } else {
      final err =
          ref.read(recordDonationProvider).error?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = ref.watch(recordDonationProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.campaign.isKafala
                        ? Icons.payments_outlined
                        : Icons.add_circle_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.campaign.isKafala
                            ? 'تسجيل دفعة كفالة'
                            : 'تسجيل تبرع',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.campaign.needyName,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.grey500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sponsor info (kafala - read only)
            if (widget.campaign.isKafala &&
                widget.campaign.sponsorName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'الكفيل: ${widget.campaign.sponsorName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Donor name (campaigns only)
            if (!widget.campaign.isKafala) ...[
              TextFormField(
                controller: _donorNameCtrl,
                decoration: InputDecoration(
                  labelText: 'اسم المتبرع',
                  prefixIcon:
                      const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAF8),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 14),
            ],

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'المبلغ (ريال)',
                prefixIcon: const Icon(Icons.monetization_on_outlined,
                    size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAF8),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'مطلوب';
                if (double.tryParse(v) == null) {
                  return 'أدخل رقماً صحيحاً';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Note
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                prefixIcon:
                    const Icon(Icons.notes_rounded, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAF8),
              ),
            ),
            const SizedBox(height: 20),

            AppButton(
              label: widget.campaign.isKafala
                  ? 'تسجيل الدفعة'
                  : 'تسجيل التبرع',
              onPressed: _submit,
              isLoading: isLoading,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
