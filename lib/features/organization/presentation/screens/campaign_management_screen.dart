import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
                    action: _filterSponsored != true
                        ? () => context.push('/org/campaign/add')
                        : null,
                    actionLabel: _filterSponsored != true
                        ? AppStrings.addCase
                        : null,
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
                        onUpdate: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _UpdateCaseSheet(
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
    required this.onUpdate,
  });

  final CampaignModel campaign;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

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
                icon: Icons.update_rounded,
                label: 'تحديث',
                color: AppColors.primary,
                onTap: onUpdate,
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
      case CampaignStatus.verified:
        color = AppColors.info;
        label = 'موثقة';
        break;
      case CampaignStatus.closed:
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

// ─── Update Case Bottom Sheet ──────────────────────────────────────────────

class _UpdateCaseSheet extends ConsumerStatefulWidget {
  const _UpdateCaseSheet({required this.campaign});
  final CampaignModel campaign;

  @override
  ConsumerState<_UpdateCaseSheet> createState() => _UpdateCaseSheetState();
}

class _UpdateCaseSheetState extends ConsumerState<_UpdateCaseSheet> {
  final _captionCtrl = TextEditingController();
  File? _image;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    final caption = _captionCtrl.text.trim();
    if (caption.isEmpty && _image == null) return;

    final ok = await ref.read(addCaseUpdateProvider.notifier).addUpdate(
          campaignId: widget.campaign.id,
          content: caption.isNotEmpty ? caption : 'تحديث جديد',
          imageFile: _image,
          sponsorId: widget.campaign.sponsorId,
          campaignTitle: widget.campaign.title,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم نشر التحديث ✅'),
        backgroundColor: AppColors.success,
      ));
    } else {
      final err = ref.read(addCaseUpdateProvider).error?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = ref.watch(addCaseUpdateProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
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
                child: const Icon(Icons.update_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نشر تحديث',
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

          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 36, color: AppColors.grey400),
                        SizedBox(height: 6),
                        Text(
                          'إضافة صورة (اختياري)',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.grey400),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Caption
          TextField(
            controller: _captionCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'نص التحديث',
              hintText: 'اكتب وصفاً للتحديث...',
              prefixIcon: const Icon(Icons.notes_rounded, size: 20),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF8FAF8),
            ),
          ),
          const SizedBox(height: 20),

          AppButton(
            label: 'نشر التحديث',
            onPressed: _submit,
            isLoading: isLoading,
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }
}
