import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/campaign_model.dart';
import '../../../../shared/widgets/campaign_card.dart';
import '../../../../shared/widgets/kafala_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/campaigns_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DonorHomeScreen extends ConsumerStatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  ConsumerState<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends ConsumerState<DonorHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final featured = ref.watch(featuredCampaignsProvider);
    final kafala = ref.watch(kafalaProvider);
    final actions = ref.watch(campaignActionsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredCampaignsProvider);
          ref.invalidate(kafalaProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ─── Hero Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroHeader(
                user: user,
                searchCtrl: _searchCtrl,
                searchQuery: _searchQuery,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                onSearchCleared: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),

            if (_searchQuery.isNotEmpty)
              _SearchResults(query: _searchQuery)
            else ...[
              // ─── Categories ──────────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _CategoriesGrid()),

              // ─── Kafala Section ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                  child: _SectionHeader(
                    title: AppStrings.kafalaList,
                    onViewAll: () => context.go('/donor/kafala'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: kafala.when(
                  data: (cases) => cases.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline,
                          title: 'لا توجد حالات كفالة متاحة',
                        )
                      : SizedBox(
                          height: 280,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: cases.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (_, i) => KafalaCard(
                              campaign: cases[i],
                              index: i,
                            ),
                          ),
                        ),
                  loading: () => const SizedBox(
                    height: 280,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // ─── Cases / Campaigns Section ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                  child: _SectionHeader(
                    title: AppStrings.featuredCampaigns,
                    onViewAll: () {},
                  ),
                ),
              ),
              featured.when(
                data: (campaigns) => campaigns.isEmpty
                    ? SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.cases_outlined,
                          title: AppStrings.noCampaigns,
                          description: AppStrings.noCampaignsDesc,
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: CampaignCard(
                                campaign: campaigns[i],
                                index: i,
                                isSaved:
                                    actions.isSaved(campaigns[i].id),
                                onSave: () =>
                                    actions.toggleSave(campaigns[i].id),
                              ),
                            ),
                            childCount: campaigns.length,
                          ),
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(
                  child: CampaignsSkeletonList(),
                ),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.user,
    required this.searchCtrl,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchCleared,
  });

  final dynamic user;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName.split(' ').first ?? 'زائر';

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.kafalaHeroTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.kafalaHeroSubtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ).animate(delay: 100.ms).fadeIn(),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/donor/profile'),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: user?.photoUrl != null
                          ? CachedNetworkImageProvider(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? Text(
                              name.isNotEmpty ? name[0] : 'م',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchHint,
                    hintStyle: const TextStyle(
                      color: AppColors.grey400,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.grey400,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: AppColors.grey400),
                            onPressed: onSearchCleared,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Categories Grid ──────────────────────────────────────────────────────────

class _CategoriesGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = [
      (KafalaType.orphan, 'أيتام', Icons.child_care_outlined, const Color(0xFF10B981)),
      (KafalaType.universityStudent, 'طلاب جامعة', Icons.school_outlined, const Color(0xFF3B82F6)),
      (KafalaType.needyFamily, 'أسر محتاجة', Icons.family_restroom_outlined, const Color(0xFFF59E0B)),
      (KafalaType.patient, 'مرضى', Icons.medical_services_outlined, const Color(0xFFEF4444)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: List.generate(categories.length, (i) {
          final (type, label, icon, color) = categories[i];
          return GestureDetector(
            onTap: () => ref
                .read(selectedKafalaTypeProvider.notifier)
                .state = type,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: i * 80))
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.92, 0.92), duration: 400.ms);
        }),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewAll,
          child: const Text(AppStrings.viewAll),
        ),
      ],
    );
  }
}

// ─── Search Results ───────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(query));
    final actions = ref.watch(campaignActionsProvider.notifier);

    return results.when(
      data: (campaigns) => campaigns.isEmpty
          ? SliverFillRemaining(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: AppStrings.noResults,
                description: AppStrings.noResultsDesc,
              ),
            )
          : SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CampaignCard(
                      campaign: campaigns[i],
                      isSaved: actions.isSaved(campaigns[i].id),
                      onSave: () => actions.toggleSave(campaigns[i].id),
                    ),
                  ),
                  childCount: campaigns.length,
                ),
              ),
            ),
      loading: () => const SliverFillRemaining(
        child: CampaignsSkeletonList(),
      ),
      error: (_, __) =>
          const SliverFillRemaining(child: SizedBox()),
    );
  }
}
