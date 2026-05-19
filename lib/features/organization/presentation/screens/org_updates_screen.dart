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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text(
              AppStrings.updates,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  _showAddForm ? Icons.close_rounded : Icons.add_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () =>
                    setState(() => _showAddForm = !_showAddForm),
              ),
            ],
          ),

          if (_showAddForm)
            SliverToBoxAdapter(
              child: _AddUpdateForm(
                onPublished: () => setState(() => _showAddForm = false),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
            ),

          // Recent updates from all cases
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _UpdateCard(entry: allUpdates[i], index: i),
                    childCount: allUpdates.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
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

// ─── Add Update Form ─────────────────────────────────────────────────────────

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

      final existing = await FirestoreService().getCampaignById(_selectedCaseId!);
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
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.addUpdate,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            // Case selector
            cases.when(
              data: (campaigns) => DropdownButtonFormField<String>(
                initialValue: _selectedCaseId,
                decoration: InputDecoration(
                  labelText: AppStrings.selectCase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
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
                validator: (v) => v == null ? 'يرجى اختيار الحالة' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: AppStrings.updateContent,
              hint: AppStrings.updateHint,
              controller: _contentCtrl,
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.errorRequired : null,
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : AppColors.grey100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case name + date
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.campaign.needyName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(entry.update.createdAt),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.grey400),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.update.content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
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
