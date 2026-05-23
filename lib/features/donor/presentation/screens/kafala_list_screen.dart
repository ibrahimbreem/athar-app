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
  // null = all, false = available, true = sponsored
  bool? _showSponsored;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final kafala = ref.watch(kafalaProvider);

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAF8),
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor:
                isDark ? AppColors.surfaceDark : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            title: Text(
              AppStrings.kafalaList,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white70 : AppColors.grey600,
                ),
                onPressed: () {},
              ),
            ],
          ),

          // ─── Search + Filters ──────────────────────────────────────
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
                  // Status filter tabs
                  Row(
                    children: [
                      _FilterTab(
                        label: 'الكل',
                        isSelected: _showSponsored == null,
                        onTap: () =>
                            setState(() => _showSponsored = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'مكفول',
                        isSelected: _showSponsored == true,
                        onTap: () =>
                            setState(() => _showSponsored = true),
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'متاح للكفالة',
                        isSelected: _showSponsored == false,
                        onTap: () =>
                            setState(() => _showSponsored = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ─── List ─────────────────────────────────────────────────
          kafala.when(
            data: (cases) {
              final filtered = _filter(cases);
              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.people_outline,
                    title: 'لا توجد حالات',
                    description:
                        'جرب تغيير الفلتر للعثور على حالات كفالة',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                child:
                    CircularProgressIndicator(color: AppColors.primary),
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

  List<CampaignModel> _filter(List<CampaignModel> cases) {
    var list = cases;
    if (_showSponsored != null) {
      list = list.where((c) => c.isSponsored == _showSponsored).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              c.needyName.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }
}

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
