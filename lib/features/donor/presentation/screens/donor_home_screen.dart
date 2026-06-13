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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: GestureDetector(
          onTap: () => context.go('/donor/profile'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: user?.photoUrl != null
                  ? CachedNetworkImageProvider(user!.photoUrl!)
                  : null,
              child: user?.photoUrl == null
                  ? Text(
                      (user?.fullName.isNotEmpty == true)
                          ? user!.fullName[0]
                          : 'م',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 4),
            Text(
              'أثر',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          _NotificationBell(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredCampaignsProvider);
          ref.invalidate(kafalaProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ─── Hero ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'كن سبباً في حياة أفضل 💚',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  height: 1.3,
                                ),
                              ).animate().fadeIn(duration: 500.ms).slideY(
                                    begin: 0.2,
                                    duration: 500.ms,
                                  ),
                              const SizedBox(height: 6),
                              Text(
                                'اختر الفئة التي تريد دعمها',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey500,
                                ),
                              ).animate(delay: 100.ms).fadeIn(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '🌱',
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                        ).animate(delay: 150.ms).scale(
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: AppStrings.searchHint,
                          hintStyle: const TextStyle(
                            color: AppColors.grey400,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 18, color: AppColors.grey400),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_searchQuery.isNotEmpty)
              _SearchResults(query: _searchQuery)
            else ...[
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ─── Categories ──────────────────────────────────────────
              SliverToBoxAdapter(child: _CategoriesRow()),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ─── Kafala Section ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
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
                          height: 395,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
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
                    height: 395,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ─── Campaigns Section ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _SectionHeader(
                    title: AppStrings.featuredCampaigns,
                    onViewAll: () => context.go('/donor/campaigns'),
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
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CampaignCard(
                                campaign: campaigns[i],
                                index: i,
                                isSaved: actions.isSaved(campaigns[i].id),
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

// ─── Categories Row ───────────────────────────────────────────────────────────

class _CategoriesRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      (
        KafalaType.orphan,
        'أيتام',
        'أطفال ينتظرون كفالتك',
        Icons.child_care_rounded,
        const Color(0xFF10B981),
        const Color(0xFFE8FBF4),
      ),
      (
        KafalaType.universityStudent,
        'طلاب جامعة',
        'ادعم تعليمهم لمستقبل أفضل',
        Icons.school_rounded,
        const Color(0xFF3B82F6),
        const Color(0xFFEFF6FF),
      ),
      (
        KafalaType.needyFamily,
        'أسر محتاجة',
        'ساعد أسرة تعيش ظروفاً صعبة',
        Icons.family_restroom_rounded,
        const Color(0xFFF59E0B),
        const Color(0xFFFFFBEB),
      ),
      (
        KafalaType.patient,
        'مرضى',
        'كن عوناً لهم في رحلة العلاج',
        Icons.favorite_rounded,
        const Color(0xFFEF4444),
        const Color(0xFFFFF1F1),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(categories.length, (i) {
          final (type, title, desc, icon, color, bg) = categories[i];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedKafalaTypeProvider.notifier).state = type;
                context.go('/donor/kafala');
              },
              child: Container(
                margin: EdgeInsets.only(
                  right: i < categories.length - 1 ? 8 : 0,
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? color.withValues(alpha: 0.3)
                        : color.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.grey500,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            )
                .animate(delay: Duration(milliseconds: i * 80))
                .fadeIn(duration: 400.ms)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  duration: 400.ms,
                ),
          );
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
        TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.chevron_left_rounded, size: 18),
          label: const Text(AppStrings.viewAll),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
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
                    padding: const EdgeInsets.only(bottom: 12),
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
      error: (_, __) => const SliverFillRemaining(child: SizedBox()),
    );
  }
}

// ─── Notification Bell with Badge ─────────────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    return IconButton(
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(fontSize: 10),
        ),
        child: Icon(
          Icons.notifications_outlined,
          color: isDark ? Colors.white70 : AppColors.grey600,
        ),
      ),
      onPressed: () => context.push('/donor/notifications'),
    );
  }
}
