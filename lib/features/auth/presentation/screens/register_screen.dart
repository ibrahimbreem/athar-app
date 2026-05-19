import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../models/user_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, required this.role});
  final UserRole role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final isOrg = widget.role == UserRole.organization;

    final user = await ref.read(authProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _nameCtrl.text.trim(),
          role: widget.role,
          phone: _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          location: isOrg ? _locationCtrl.text.trim() : null,
          story: isOrg && _descCtrl.text.trim().isNotEmpty
              ? _descCtrl.text.trim()
              : null,
        );

    if (!mounted) return;

    if (user != null) {
      if (user.role == UserRole.organization) {
        context.go('/org/dashboard');
      } else {
        context.go('/donor/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isOrg = widget.role == UserRole.organization;

    ref.listen(authProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) => context.showErrorSnackBar(e.toString()),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isOrg ? 'تسجيل جمعية / منظمة' : 'إنشاء حساب متبرع'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.white],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOrg
                            ? Icons.business_rounded
                            : Icons.favorite_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOrg ? 'جمعية / منظمة' : 'متبرع كريم',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          isOrg
                              ? 'أضف حالاتك وتابع كفالتها'
                              : 'ساهم في بناء مجتمع أفضل',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic info
              _SectionTitle(
                icon: isOrg ? Icons.business_outlined : Icons.person_outline,
                title: isOrg ? 'معلومات الجمعية' : 'المعلومات الشخصية',
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: isOrg ? 'اسم الجمعية / المنظمة' : AppStrings.fullName,
                controller: _nameCtrl,
                validator: Validators.required,
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  isOrg ? Icons.business_outlined : Icons.person_outline,
                  size: 20,
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: AppStrings.email,
                controller: _emailCtrl,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: AppStrings.phone,
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),

              // Organization-only fields
              if (isOrg) ...[
                const SizedBox(height: 24),
                const _SectionTitle(
                  icon: Icons.info_outline_rounded,
                  title: 'تفاصيل الجمعية',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'المدينة / الموقع',
                  controller: _locationCtrl,
                  textInputAction: TextInputAction.next,
                  prefixIcon:
                      const Icon(Icons.location_on_outlined, size: 20),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'نبذة عن الجمعية',
                  hint: 'اشرح باختصار أهداف جمعيتك ومجال عملها...',
                  controller: _descCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  prefixIcon:
                      const Icon(Icons.description_outlined, size: 20),
                ),
              ],

              const SizedBox(height: 24),
              const _SectionTitle(
                icon: Icons.lock_outline,
                title: 'كلمة المرور',
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: AppStrings.password,
                controller: _passwordCtrl,
                validator: Validators.password,
                obscureText: true,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: AppStrings.confirmPassword,
                controller: _confirmCtrl,
                validator: (v) =>
                    Validators.confirmPassword(v, _passwordCtrl.text),
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                onFieldSubmitted: (_) => _register(),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: AppStrings.register,
                onPressed: _register,
                isLoading: authState.isLoading,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.haveAccount,
                    style: context.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(AppStrings.login),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: AppColors.grey200)),
      ],
    );
  }
}
