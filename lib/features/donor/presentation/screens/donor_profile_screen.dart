import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/campaign_card.dart';
import '../providers/campaigns_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DonorProfileScreen extends ConsumerWidget {
  const DonorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined,
                  size: 64, color: AppColors.grey300),
              const SizedBox(height: 16),
              Text('يرجى تسجيل الدخول للوصول لحسابك',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/role-selection'),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: user.photoUrl != null
                            ? CachedNetworkImageProvider(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0]
                                    : 'م',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ).animate(delay: 100.ms).fadeIn(),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(
                            label: 'حالات متابَعة',
                            value: '${user.followedCases.length}',
                          ),
                          const SizedBox(width: 16),
                          _StatChip(
                            label: 'حالات محفوظة',
                            value: '${user.savedCases.length}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ─── Saved Campaigns ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppStrings.savedCases,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          _SavedCampaignsSection(),

          // ─── Settings ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                'الإعدادات',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2D3748)
                        : AppColors.grey100,
                  ),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      label: AppStrings.editProfile,
                      onTap: () {},
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      label: AppStrings.darkMode,
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (_) => themeNotifier.toggle(),
                        activeColor: AppColors.primary,
                      ),
                      onTap: () => themeNotifier.toggle(),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: AppStrings.notifications_settings,
                      onTap: () {},
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      label: AppStrings.privacy,
                      onTap: () {},
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: AppStrings.aboutApp,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ─── Logout ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await context.showConfirmDialog(
                    title: 'تسجيل الخروج',
                    message: 'هل أنت متأكد من تسجيل الخروج؟',
                    confirmText: 'خروج',
                    isDestructive: true,
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(authProvider.notifier).signOut();
                    context.go('/role-selection');
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text(
                  AppStrings.logout,
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SavedCampaignsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedCampaignsProvider);
    final actions = ref.watch(campaignActionsProvider.notifier);

    return saved.when(
      data: (campaigns) => campaigns.isEmpty
          ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_border,
                          color: AppColors.grey400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.noSavedCampaignsDesc,
                          style: const TextStyle(color: AppColors.grey500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: campaigns.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => SizedBox(
                    width: 260,
                    child: CampaignCard(
                      campaign: campaigns[i],
                      index: i,
                      isSaved: true,
                      onSave: () => actions.toggleSave(campaigns[i].id),
                    ),
                  ),
                ),
              ),
            ),
      loading: () => const SliverToBoxAdapter(
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.grey500),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_left_rounded,
                    color: AppColors.grey300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 50);
  }
}
