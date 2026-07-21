import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';

class PersonalInformationData {
  final String fullName;
  final String partnerId;
  final String phone;
  final String email;
  final String dateOfBirth;
  final String gender;
  final String emergencyContactName;
  final String emergencyContactPhone;

  const PersonalInformationData({
    required this.fullName,
    required this.partnerId,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  PersonalInformationData copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? dateOfBirth,
    String? gender,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return PersonalInformationData(
      fullName: fullName ?? this.fullName,
      partnerId: partnerId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}

const mockPersonalInformation = PersonalInformationData(
  fullName: 'Rahul Verma',
  partnerId: 'ZP12345678',
  phone: '98765 43210',
  email: 'rahul.verma@example.com',
  dateOfBirth: '18 August 1996',
  gender: 'Male',
  emergencyContactName: 'Suresh Verma',
  emergencyContactPhone: '98123 45678',
);

class PersonalInformationSheet extends StatefulWidget {
  final PersonalInformationData information;

  const PersonalInformationSheet({
    super.key,
    required this.information,
  });

  static Future<PersonalInformationData?> show(
    BuildContext context, {
    required PersonalInformationData information,
  }) {
    return showModalBottomSheet<PersonalInformationData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.primary.withValues(alpha: 0.48),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: PersonalInformationSheet(information: information),
      ),
    );
  }

  @override
  State<PersonalInformationSheet> createState() =>
      _PersonalInformationSheetState();
}

class _PersonalInformationSheetState extends State<PersonalInformationSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _genderController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.information.fullName);
    _phoneController = TextEditingController(text: widget.information.phone);
    _emailController = TextEditingController(text: widget.information.email);
    _dateOfBirthController =
        TextEditingController(text: widget.information.dateOfBirth);
    _genderController = TextEditingController(text: widget.information.gender);
    _emergencyNameController =
        TextEditingController(text: widget.information.emergencyContactName);
    _emergencyPhoneController =
        TextEditingController(text: widget.information.emergencyContactPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _genderController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _cancelEditing() {
    _nameController.text = widget.information.fullName;
    _phoneController.text = widget.information.phone;
    _emailController.text = widget.information.email;
    _dateOfBirthController.text = widget.information.dateOfBirth;
    _genderController.text = widget.information.gender;
    _emergencyNameController.text = widget.information.emergencyContactName;
    _emergencyPhoneController.text = widget.information.emergencyContactPhone;
    setState(() => _isEditing = false);
  }

  void _save() {
    final updated = widget.information.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      dateOfBirth: _dateOfBirthController.text.trim(),
      gender: _genderController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: AppMotion.duration(context, AppMotion.quick),
      curve: AppMotion.enter,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        child: Column(
          children: [
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBg,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Personal Information', style: AppTypography.h2),
                        Text(
                          _isEditing
                              ? 'Update the details you want to change'
                              : 'Your account and contact details',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IdentitySummary(information: widget.information),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionLabel(
                      title: 'Contact details',
                      subtitle: 'Used for delivery and account updates',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InformationField(
                      key: const Key('personal_name_field'),
                      label: 'Full name',
                      icon: LucideIcons.user,
                      controller: _nameController,
                      enabled: _isEditing,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InformationField(
                      key: const Key('personal_phone_field'),
                      label: 'Mobile number',
                      icon: LucideIcons.phone,
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InformationField(
                      key: const Key('personal_email_field'),
                      label: 'Email address',
                      icon: LucideIcons.mail,
                      controller: _emailController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionLabel(
                      title: 'Basic details',
                      subtitle: 'Personal information on your profile',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InformationField(
                            label: 'Date of birth',
                            icon: LucideIcons.calendarDays,
                            controller: _dateOfBirthController,
                            enabled: _isEditing,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _InformationField(
                            label: 'Gender',
                            icon: LucideIcons.userCircle,
                            controller: _genderController,
                            enabled: _isEditing,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionLabel(
                      title: 'Emergency contact',
                      subtitle: 'Someone we can contact when you need help',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InformationField(
                      label: 'Contact name',
                      icon: LucideIcons.users,
                      controller: _emergencyNameController,
                      enabled: _isEditing,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InformationField(
                      label: 'Contact number',
                      icon: LucideIcons.phone,
                      controller: _emergencyPhoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: _isEditing
                    ? Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton(
                                onPressed: _cancelEditing,
                                style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.button),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: PrimaryCtaButton(
                              label: 'Save changes',
                              trailingIcon: LucideIcons.check,
                              onPressed: _save,
                            ),
                          ),
                        ],
                      )
                    : PrimaryCtaButton(
                        label: 'Edit information',
                        trailingIcon: LucideIcons.edit3,
                        onPressed: () => setState(() => _isEditing = true),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
    );
  }
}

class _IdentitySummary extends StatelessWidget {
  final PersonalInformationData information;

  const _IdentitySummary({required this.information});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySoft, Color(0xFFDDE3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              information.fullName
                  .split(' ')
                  .where((part) => part.isNotEmpty)
                  .take(2)
                  .map((part) => part[0])
                  .join()
                  .toUpperCase(),
              style: AppTypography.h2.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(information.fullName, style: AppTypography.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'Partner ID: ${information.partnerId}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.badgeCheck,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Verified',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTypography.caption),
      ],
    );
  }
}

class _InformationField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _InformationField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.enabled,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: !enabled,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 19,
          color: enabled ? AppColors.secondary : AppColors.textSecondary,
        ),
        suffixIcon: enabled
            ? const Icon(
                LucideIcons.edit3,
                size: 16,
                color: AppColors.secondary,
              )
            : null,
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surfaceMuted,
      ),
    );
  }
}

@Preview(
  name: 'Personal Information Sheet',
  group: 'Profile',
  size: Size(390, 780),
)
Widget personalInformationSheetPreview() => MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: PersonalInformationSheet(
            information: mockPersonalInformation,
          ),
        ),
      ),
    );
