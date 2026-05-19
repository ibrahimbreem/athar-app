import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../services/firebase_auth_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OrgSettingsScreen extends ConsumerStatefulWidget {
  const OrgSettingsScreen({super.key});

  @override
  ConsumerState<OrgSettingsScreen> createState() => _OrgSettingsScreenState();
}

class _OrgSettingsScreenState extends ConsumerState<OrgSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _storyCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.fullName);
    _locationCtrl = TextEditingController(text: user?.location);
    _storyCtrl = TextEditingController(text: user?.story);
    _phoneCtrl = TextEditingController(text: user?.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _storyCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuthService().updateUserData(user.id, {
        'fullName': _nameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'story': _storyCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        context.showSuccessSnackBar(AppStrings.successProfileUpdated);
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final file = await StorageService().pickImage();
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      final url = await StorageService().uploadUserAvatar(file, user.id);
      await FirebaseAuthService().updateUserData(user.id, {'photoUrl': url});
      if (mounted) context.showSuccessSnackBar('تم تحديث الصورة');
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Avatar ────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: user?.photoUrl != null
                        ? CachedNetworkImageProvider(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName[0]
                                : 'م',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (user?.isVerified == true) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        AppStrings.verifiedOrg,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ─── Profile Form ──────────────────────────────────────
            Text(
              'المعلومات الشخصية',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    label: AppStrings.fullName,
                    controller: _nameCtrl,
                    validator: Validators.required,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.phone,
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.needyLocation,
                    controller: _locationCtrl,
                    textInputAction: TextInputAction.next,
                    prefixIcon:
                        const Icon(Icons.location_on_outlined, size: 20),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.needyStory,
                    controller: _storyCtrl,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    prefixIcon:
                        const Icon(Icons.description_outlined, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: AppStrings.save,
              onPressed: _saveProfile,
              isLoading: _isLoading,
              icon: Icons.save_outlined,
            ),

            const SizedBox(height: 28),

            // ─── App Settings ──────────────────────────────────────
            Text(
              'إعدادات التطبيق',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF2D3748)
                      : AppColors.grey100,
                ),
              ),
              child: Column(
                children: [
                  _SettingRow(
                    icon: isDarkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: AppStrings.darkMode,
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 1),
                  _SettingRow(
                    icon: Icons.notifications_outlined,
                    label: AppStrings.notifications_settings,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _SettingRow(
                    icon: Icons.privacy_tip_outlined,
                    label: AppStrings.privacy,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _SettingRow(
                    icon: Icons.info_outline,
                    label: AppStrings.aboutApp,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await context.showConfirmDialog(
                  title: 'تسجيل الخروج',
                  message: 'هل تريد تسجيل الخروج من حسابك؟',
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.grey500),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.titleSmall),
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
