import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../models/campaign_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/org_provider.dart';

class OrgUpdatesScreen extends ConsumerStatefulWidget {
  const OrgUpdatesScreen({super.key});

  @override
  ConsumerState<OrgUpdatesScreen> createState() => _OrgUpdatesScreenState();
}

class _OrgUpdatesScreenState extends ConsumerState<OrgUpdatesScreen> {
  bool _showAddForm = false;

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(orgCasesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAF8),
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            title: const Text(
              AppStrings.updates,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: true,
            actions: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showAddForm
                    ? IconButton(
                        key: const ValueKey('close'),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.error),
                        onPressed: () =>
                            setState(() => _showAddForm = false),
                      )
                    : IconButton(
                        key: const ValueKey('add'),
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.primary),
                        tooltip: AppStrings.addUpdate,
                        onPressed: () =>
                            setState(() => _showAddForm = true),
                      ),
              ),
            ],
          ),

          // ─── Add Update Form ─────────────────────────────────────
          if (_showAddForm)
            SliverToBoxAdapter(
              child: _AddUpdateForm(
                onPublished: () => setState(() => _showAddForm = false),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.08),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ─── Updates List ────────────────────────────────────────
          cases.when(
            data: (campaigns) {
              final allUpdates = <_UpdateEntry>[];
              for (final c in campaigns) {
                for (final u in c.updates) {
                  allUpdates.add(_UpdateEntry(campaign: c, update: u));
                }
              }
              allUpdates.sort((a, b) =>
                  b.update.createdAt.compareTo(a.update.createdAt));

              if (allUpdates.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.update_rounded,
                    title: AppStrings.noUpdates,
                    description: AppStrings.noUpdatesDesc,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _UpdateCard(entry: allUpdates[i], index: i),
                    childCount: allUpdates.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child:
                  Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (_, __) => const SliverFillRemaining(child: SizedBox()),
          ),
        ],
      ),
    );
  }
}

class _UpdateEntry {
  final CampaignModel campaign;
  final CampaignUpdate update;
  const _UpdateEntry({required this.campaign, required this.update});
}

// ─── Add Update Form ──────────────────────────────────────────────────────────

class _AddUpdateForm extends ConsumerStatefulWidget {
  const _AddUpdateForm({required this.onPublished});
  final VoidCallback onPublished;

  @override
  ConsumerState<_AddUpdateForm> createState() => _AddUpdateFormState();
}

class _AddUpdateFormState extends ConsumerState<_AddUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  final _contentCtrl = TextEditingController();
  String? _selectedCaseId;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCaseId == null) {
      context.showErrorSnackBar('يرجى اختيار الحالة');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final update = CampaignUpdate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _contentCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      final existing =
          await FirestoreService().getCampaignById(_selectedCaseId!);
      if (existing == null) throw Exception('الحالة غير موجودة');

      final updatedUpdates = [...existing.updates, update];
      await FirestoreService().updateCampaign(_selectedCaseId!, {
        'updates': updatedUpdates.map((u) => u.toMap()).toList(),
      });

      if (mounted) {
        context.showSuccessSnackBar('تم نشر التحديث بنجاح');
        widget.onPublished();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(orgCasesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Text(
                  AppStrings.addUpdate,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Case selector
            cases.when(
              data: (campaigns) => DropdownButtonFormField<String>(
                initialValue: _selectedCaseId,
                decoration: InputDecoration(
                  labelText: AppStrings.selectCase,
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.grey200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAF8),
                ),
                items: campaigns
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.needyName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCaseId = v),
                validator: (v) =>
                    v == null ? 'يرجى اختيار الحالة' : null,
              ),
              loading: () => const LinearProgressIndicator(
                  color: AppColors.primary),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 14),

            AppTextField(
              label: AppStrings.updateContent,
              hint: AppStrings.updateHint,
              controller: _contentCtrl,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.errorRequired
                  : null,
            ),

            const SizedBox(height: 16),

            AppButton(
              label: AppStrings.publishUpdate,
              onPressed: _publish,
              isLoading: _isLoading,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Update Card ──────────────────────────────────────────────────────────────

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.entry, required this.index});
  final _UpdateEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry.campaign.needyName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(entry.update.createdAt),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.grey400),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              entry.update.content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0, duration: 350.ms);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
