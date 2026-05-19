import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/campaign_model.dart';
import '../../../../shared/widgets/campaign_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/campaigns_provider.dart';

class DonorCampaignsScreen extends ConsumerStatefulWidget {
  const DonorCampaignsScreen({super.key});

  @override
  ConsumerState<DonorCampaignsScreen> createState() =>
      _DonorCampaignsScreenState();
}

class _DonorCampaignsScreenState extends ConsumerState<DonorCampaignsScreen> {
  CampaignCategory? _selected;

  static const _filters = [
    (null, 'الكل'),
    (CampaignCategory.medical, 'طبي'),
    (CampaignCategory.education, 'تعليمي'),
    (CampaignCategory.food, 'غذاء'),
    (CampaignCategory.housing, 'مسكن'),
    (CampaignCategory.orphan, 'أيتام'),
    (CampaignCategory.disaster, 'كوارث'),
  ];

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allActiveCampaignsProvider);
    final actions = ref.watch(campaignActionsProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text(
              AppStrings.campaigns,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),

          // Category filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (cat, label) = _filters[i];
                    final isSelected = _selected == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selected = cat);
                        ref
                            .read(selectedCategoryProvider.notifier)
                            .state = cat;
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
            ),
          ),

          // Campaigns list
          all.when(
            data: (campaigns) {
              final filtered = _selected == null
                  ? campaigns
                  : campaigns
                      .where((c) => c.category == _selected)
                      .toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.cases_outlined,
                    title: AppStrings.noCampaigns,
                    description: AppStrings.noCampaignsDesc,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CampaignCard(
                        campaign: filtered[i],
                        index: i,
                        isSaved: actions.isSaved(filtered[i].id),
                        onSave: () => actions.toggleSave(filtered[i].id),
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: CampaignsSkeletonList()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox()),
          ),
        ],
      ),
    );
  }
}
