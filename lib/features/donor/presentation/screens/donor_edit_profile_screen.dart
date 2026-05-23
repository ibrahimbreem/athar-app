import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../services/firebase_auth_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DonorEditProfileScreen extends ConsumerStatefulWidget {
  const DonorEditProfileScreen({super.key});

  @override
  ConsumerState<DonorEditProfileScreen> createState() =>
      _DonorEditProfileScreenState();
}

class _DonorEditProfileScreenState
    extends ConsumerState<DonorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.fullName);
    _phoneCtrl = TextEditingController(text: user?.phone);
    _locationCtrl = TextEditingController(text: user?.location);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuthService().updateUserData(user.id, {
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      });
      ref.read(currentUserProvider.notifier).setUser(
            user.copyWith(
              fullName: _nameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              location: _locationCtrl.text.trim(),
            ),
          );
      if (mounted) {
        context.showSuccessSnackBar(AppStrings.successProfileUpdated);
        Navigator.of(context).pop();
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
      ref
          .read(currentUserProvider.notifier)
          .setUser(user.copyWith(photoUrl: url));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
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
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0]
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
                      onTap: _isLoading ? null : _pickAvatar,
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

            const SizedBox(height: 32),

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
                    textInputAction: TextInputAction.done,
                    prefixIcon:
                        const Icon(Icons.location_on_outlined, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            AppButton(
              label: AppStrings.save,
              onPressed: _save,
              isLoading: _isLoading,
              icon: Icons.save_outlined,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
