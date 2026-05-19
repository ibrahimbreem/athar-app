import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/campaign_model.dart';
import '../../../../shared/widgets/kafala_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/campaigns_provider.dart';

class KafalaListScreen extends ConsumerStatefulWidget {
  const KafalaListScreen({super.key});

  @override
  ConsumerState<KafalaListScreen> createState() => _KafalaListScreenState();
}

class _KafalaListScreenState extends ConsumerState<KafalaListScreen> {
  KafalaType? _selectedType;
  bool? _showSponsored; // null = all, false = available, true = sponsored

  static const _statusFilters = [
    (null, 'الكل'),
    (false, 'متاح للكفالة'),
    (true, 'مكفول'),
  ];

  static const _typeFilters = [
    (null, 'الكل'),
    (KafalaType.orphan, 'أيتام'),
    (KafalaType.universityStudent, 'طلاب جامعة'),
    (KafalaType.needyFamily, 'أسر محتاجة'),
    (KafalaType.patient, 'مرضى'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kafala = ref.watch(kafalaProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            title: const Text(
              AppStrings.kafalaList,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),

          // ─── Type Filter Chips ───────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'نوع الكفالة',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _typeFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final (type, label) = _typeFilters[i];
                      final isSelected = _selectedType == type;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = type);
                          ref
                              .read(selectedKafalaTypeProvider.notifier)
                              .state = type;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.grey600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Status filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'الحالة',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final (isSponsored, label) = _statusFilters[i];
                      final isSelected = _showSponsored == isSponsored;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _showSponsored = isSponsored),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.grey600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ─── List ─────────────────────────────────────────────────
          kafala.when(
            data: (cases) {
              final filtered = _filterCases(cases);
              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.people_outline,
                    title: 'لا توجد حالات',
                    description: 'جرب تغيير الفلتر للعثور على حالات كفالة',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => KafalaListCard(
                      campaign: filtered[i],
                      index: i,
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, __) => const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'حدث خطأ',
                description: 'يرجى المحاولة مرة أخرى',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CampaignModel> _filterCases(List<CampaignModel> cases) {
    if (_showSponsored == null) return cases;
    return cases
        .where((c) => c.isSponsored == _showSponsored)
        .toList();
  }
}
