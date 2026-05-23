import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/campaign_model.dart';
import '../../../../services/storage_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/org_provider.dart';

class CampaignFormScreen extends ConsumerStatefulWidget {
  const CampaignFormScreen({super.key, this.campaignId});
  final String? campaignId;

  bool get isEdit => campaignId != null;

  @override
  ConsumerState<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends ConsumerState<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _needsCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _personNameCtrl = TextEditingController();
  final _personAgeCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();
  final _monthlyAmountCtrl = TextEditingController();

  CampaignCategory _category = CampaignCategory.other;
  UrgencyLevel _urgency = UrgencyLevel.medium;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];

  // Kafala toggle
  bool _isKafala = false;
  KafalaType? _kafalaType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(campaignFormProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _needsCtrl.dispose();
    _locationCtrl.dispose();
    _personNameCtrl.dispose();
    _personAgeCtrl.dispose();
    _goalAmountCtrl.dispose();
    _monthlyAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await StorageService().pickMultipleImages(max: 5);
    if (files.isNotEmpty) {
      setState(() => _newImages = [..._newImages, ...files]);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isKafala && _kafalaType == null) {
      context.showErrorSnackBar('يرجى اختيار نوع الكفالة');
      return;
    }
    FocusScope.of(context).unfocus();

    final notifier = ref.read(campaignFormProvider.notifier);
    bool ok;

    if (widget.isEdit) {
      ok = await notifier.updateCampaign(
        widget.campaignId!,
        {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'needs': _needsCtrl.text.trim().isEmpty
              ? null
              : _needsCtrl.text.trim(),
          'location': _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          'category': _category.name,
          'urgencyLevel': _urgency.name,
          if (_isKafala) 'kafalaType': _kafalaType?.name,
          if (_isKafala && _personAgeCtrl.text.isNotEmpty)
            'personAge': int.tryParse(_personAgeCtrl.text),
          if (_isKafala && _personNameCtrl.text.trim().isNotEmpty)
            'needyName': _personNameCtrl.text.trim(),
        },
        _newImages,
        _existingImageUrls,
      );
    } else {
      ok = await notifier.addCampaign(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        needs: _needsCtrl.text.trim().isEmpty ? null : _needsCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        category: _category,
        urgencyLevel: _urgency,
        images: _newImages,
        kafalaType: _isKafala ? _kafalaType : null,
        personAge: _isKafala && _personAgeCtrl.text.isNotEmpty
            ? int.tryParse(_personAgeCtrl.text)
            : null,
        personName: _isKafala ? _personNameCtrl.text.trim() : null,
        goalAmount: !_isKafala && _goalAmountCtrl.text.isNotEmpty
            ? double.tryParse(_goalAmountCtrl.text)
            : null,
        monthlyAmount: _isKafala && _monthlyAmountCtrl.text.isNotEmpty
            ? double.tryParse(_monthlyAmountCtrl.text)
            : null,
      );
    }

    if (!mounted) return;

    if (ok) {
      context.showSuccessSnackBar(
        widget.isEdit
            ? AppStrings.successCampaignUpdated
            : AppStrings.successCampaignAdded,
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(campaignFormProvider);
    final theme = Theme.of(context);

    ref.listen(campaignFormProvider, (_, next) {
      if (next.error != null) {
        context.showErrorSnackBar(next.error!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? AppStrings.editCase : AppStrings.addCase),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── Case Type Toggle ─────────────────────────────────
            if (!widget.isEdit) ...[
              _FormLabel(label: 'نوع الحالة', icon: Icons.category_outlined),
              const SizedBox(height: 10),
              _CaseTypeToggle(
                isKafala: _isKafala,
                onChanged: (v) => setState(() {
                  _isKafala = v;
                  _kafalaType = null;
                }),
              ),
              const SizedBox(height: 20),
            ],

            // ─── Kafala Fields ────────────────────────────────────
            if (_isKafala) ...[
              _FormLabel(
                  label: 'نوع الكفالة', icon: Icons.favorite_outline_rounded),
              const SizedBox(height: 10),
              _KafalaTypeSelector(
                selected: _kafalaType,
                onSelect: (t) => setState(() => _kafalaType = t),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'اسم الشخص',
                hint: 'الاسم الكامل للمستفيد',
                controller: _personNameCtrl,
                validator: Validators.required,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline, size: 20),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'العمر (بالسنوات)',
                hint: 'مثال: 12',
                controller: _personAgeCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.cake_outlined, size: 20),
              ),
              const SizedBox(height: 14),
              // ─── Monthly amount for kafala ───────────────────────
              AppTextField(
                label: 'مبلغ الكفالة الشهرية (ريال)',
                hint: 'مثال: 500',
                controller: _monthlyAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.payments_outlined, size: 20),
              ),
              const SizedBox(height: 24),
            ],

            // ─── Images Picker ─────────────────────────────────────
            _ImagePickerSection(
              images: _newImages,
              existingUrls: _existingImageUrls,
              onPick: _pickImages,
              onRemoveNew: (i) => setState(() => _newImages.removeAt(i)),
              onRemoveExisting: (i) =>
                  setState(() => _existingImageUrls.removeAt(i)),
            ),
            const SizedBox(height: 24),

            // ─── Title ─────────────────────────────────────────────
            AppTextField(
              label: _isKafala ? 'عنوان الحالة' : AppStrings.caseTitle,
              hint: _isKafala
                  ? 'مثال: كفالة يتيم - محافظة الرياض'
                  : 'أدخل عنواناً واضحاً ومؤثراً للحالة',
              controller: _titleCtrl,
              validator: Validators.required,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.title_rounded, size: 20),
            ),
            const SizedBox(height: 16),

            // ─── Description ───────────────────────────────────────
            AppTextField(
              label: AppStrings.caseDesc,
              hint: 'اشرح تفاصيل الحالة وظروفها...',
              controller: _descCtrl,
              validator: Validators.required,
              maxLines: 4,
              prefixIcon: const Icon(Icons.description_outlined, size: 20),
            ),
            const SizedBox(height: 16),

            // ─── Location ──────────────────────────────────────────
            AppTextField(
              label: AppStrings.caseLocation,
              hint: 'المدينة أو المنطقة',
              controller: _locationCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            ),
            const SizedBox(height: 16),

            // ─── Goal amount (campaigns only) ──────────────────────
            if (!_isKafala) ...[
              AppTextField(
                label: 'المبلغ المستهدف (ريال)',
                hint: 'مثال: 10000',
                controller: _goalAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.track_changes_rounded, size: 20),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Needs (hidden for kafala) ─────────────────────────
            if (!_isKafala) ...[
              AppTextField(
                label: AppStrings.caseNeeds,
                hint: 'ما الذي تحتاجه هذه الحالة تحديداً؟',
                controller: _needsCtrl,
                maxLines: 3,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.list_alt_outlined, size: 20),
              ),
              const SizedBox(height: 20),
            ],

            // ─── Category ──────────────────────────────────────────
            _FormLabel(label: 'التصنيف', icon: Icons.category_outlined),
            const SizedBox(height: 10),
            _CategorySelector(
              selected: _category,
              onSelect: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 20),

            // ─── Urgency ───────────────────────────────────────────
            _FormLabel(
                label: 'مستوى الأولوية',
                icon: Icons.priority_high_rounded),
            const SizedBox(height: 10),
            _UrgencySelector(
              selected: _urgency,
              onSelect: (u) => setState(() => _urgency = u),
            ),

            // ─── Upload progress ───────────────────────────────────
            if (formState.isLoading && formState.uploadProgress > 0) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: formState.uploadProgress,
                  minHeight: 6,
                  backgroundColor: AppColors.grey100,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'جارٍ رفع الصور: ${(formState.uploadProgress * 100).toInt()}%',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),
            AppButton(
              label: widget.isEdit ? AppStrings.update : AppStrings.submit,
              onPressed: _submit,
              isLoading: formState.isLoading,
              icon: widget.isEdit
                  ? Icons.update_rounded
                  : Icons.send_rounded,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Case Type Toggle ─────────────────────────────────────────────────────────

class _CaseTypeToggle extends StatelessWidget {
  const _CaseTypeToggle(
      {required this.isKafala, required this.onChanged});
  final bool isKafala;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !isKafala ? AppColors.primary : AppColors.grey100,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cases_outlined,
                    color: !isKafala ? Colors.white : AppColors.grey500,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'حالة عادية',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: !isKafala ? Colors.white : AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isKafala ? AppColors.primary : AppColors.grey100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_outline_rounded,
                    color: isKafala ? Colors.white : AppColors.grey500,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'حالة كفالة',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isKafala ? Colors.white : AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Kafala Type Selector ─────────────────────────────────────────────────────

class _KafalaTypeSelector extends StatelessWidget {
  const _KafalaTypeSelector(
      {required this.selected, required this.onSelect});
  final KafalaType? selected;
  final void Function(KafalaType) onSelect;

  static const _items = [
    (KafalaType.orphan, 'أيتام', Icons.child_care_outlined, Color(0xFF10B981)),
    (KafalaType.universityStudent, 'طلاب جامعة', Icons.school_outlined,
        Color(0xFF3B82F6)),
    (KafalaType.needyFamily, 'أسر محتاجة', Icons.family_restroom_outlined,
        Color(0xFFF59E0B)),
    (KafalaType.patient, 'مرضى', Icons.medical_services_outlined,
        Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: _items.map((item) {
        final (type, label, icon, color) = item;
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onSelect(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: isSelected ? color : AppColors.grey500, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSelected ? color : AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onSelect});
  final CampaignCategory selected;
  final void Function(CampaignCategory) onSelect;

  static const _items = [
    (CampaignCategory.medical, 'طبي', Icons.medical_services_outlined),
    (CampaignCategory.education, 'تعليمي', Icons.school_outlined),
    (CampaignCategory.food, 'غذاء', Icons.restaurant_outlined),
    (CampaignCategory.housing, 'مسكن', Icons.home_outlined),
    (CampaignCategory.orphan, 'أيتام', Icons.child_care_outlined),
    (CampaignCategory.disaster, 'كوارث', Icons.warning_amber_outlined),
    (CampaignCategory.environment, 'بيئة', Icons.eco_outlined),
    (CampaignCategory.other, 'أخرى', Icons.more_horiz_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _items.map((item) {
        final (cat, label, icon) = item;
        final isSelected = selected == cat;
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.grey100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 14,
                    color: isSelected ? Colors.white : AppColors.grey600),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _UrgencySelector extends StatelessWidget {
  const _UrgencySelector({required this.selected, required this.onSelect});
  final UrgencyLevel selected;
  final void Function(UrgencyLevel) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UrgencyOption(
          label: 'عاجل',
          color: AppColors.urgencyHigh,
          isSelected: selected == UrgencyLevel.high,
          onTap: () => onSelect(UrgencyLevel.high),
        ),
        const SizedBox(width: 10),
        _UrgencyOption(
          label: 'متوسط',
          color: AppColors.urgencyMedium,
          isSelected: selected == UrgencyLevel.medium,
          onTap: () => onSelect(UrgencyLevel.medium),
        ),
        const SizedBox(width: 10),
        _UrgencyOption(
          label: 'عادي',
          color: AppColors.urgencyLow,
          isSelected: selected == UrgencyLevel.low,
          onTap: () => onSelect(UrgencyLevel.low),
        ),
      ],
    );
  }
}

class _UrgencyOption extends StatelessWidget {
  const _UrgencyOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({
    required this.images,
    required this.existingUrls,
    required this.onPick,
    required this.onRemoveNew,
    required this.onRemoveExisting,
  });

  final List<File> images;
  final List<String> existingUrls;
  final VoidCallback onPick;
  final void Function(int) onRemoveNew;
  final void Function(int) onRemoveExisting;

  @override
  Widget build(BuildContext context) {
    final hasImages = images.isNotEmpty || existingUrls.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormLabel(label: 'صور الحالة', icon: Icons.image_outlined),
        const SizedBox(height: 10),
        if (hasImages)
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...existingUrls.asMap().entries.map((e) => _ImageThumb(
                      child: Image.network(e.value, fit: BoxFit.cover),
                      onRemove: () => onRemoveExisting(e.key),
                    )),
                ...images.asMap().entries.map((e) => _ImageThumb(
                      child: Image.file(e.value, fit: BoxFit.cover),
                      onRemove: () => onRemoveNew(e.key),
                    )),
                _AddImageButton(onTap: onPick),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text(
                    'اضغط لإضافة صور',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.child, required this.onRemove});
  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 100, height: 100, child: child),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primary, size: 24),
            SizedBox(height: 4),
            Text('إضافة',
                style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
