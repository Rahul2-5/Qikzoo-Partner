import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validators/validators.dart';
import '../../../models/bank_details/bank_details_model.dart';
import '../../../providers/bank_details/bank_details_provider.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../profile/widgets/account_screen_components.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  bool _didPopulate = false;
  String? _holderError;
  String? _accountError;
  String? _confirmAccountError;
  String? _ifscError;
  String? _upiError;

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _populate(BankDetailsModel? details) {
    if (_didPopulate) return;
    _didPopulate = true;
    if (details == null) return;
    _holderController.text = details.accountHolderName;
    _accountController.text = details.accountNumber;
    _confirmAccountController.text = details.accountNumber;
    _ifscController.text = details.ifsc;
    _upiController.text = details.upiId ?? '';
  }

  bool _validate() {
    final holder = _holderController.text.trim();
    final account = _accountController.text.trim();
    final confirmation = _confirmAccountController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    final upi = _upiController.text.trim();

    setState(() {
      _holderError = holder.length < 3 ? 'Enter the account holder name' : null;
      _accountError = account.length < 9 || account.length > 18
          ? 'Enter a valid account number'
          : null;
      _confirmAccountError =
          confirmation != account ? 'Account numbers do not match' : null;
      _ifscError = Validators.isValidIfsc(ifsc)
          ? null
          : 'Enter a valid 11-character IFSC code';
      _upiError = upi.isNotEmpty &&
              !RegExp(r'^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+$').hasMatch(upi)
          ? 'Enter a valid UPI ID'
          : null;
    });

    return [
      _holderError,
      _accountError,
      _confirmAccountError,
      _ifscError,
      _upiError,
    ].every((error) => error == null);
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final details = BankDetailsModel(
      accountHolderName: _holderController.text.trim(),
      accountNumber: _accountController.text.trim(),
      ifsc: _ifscController.text.trim().toUpperCase(),
      upiId: _upiController.text.trim().isEmpty
          ? null
          : _upiController.text.trim(),
    );
    await ref.read(bankDetailsProvider.notifier).save(details);
    if (!mounted) return;

    final result = ref.read(bankDetailsProvider);
    if (result.hasError) {
      AppSnackBar.error(context, 'Could not save bank details. Try again.');
      return;
    }

    AppSnackBar.success(context, 'Bank details saved securely');
    if (Get.previousRoute == AppRoutes.selfieVerification) {
      Get.offNamed(AppRoutes.verificationStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(bankDetailsProvider);
    if (detailsAsync.hasValue) _populate(detailsAsync.valueOrNull);

    final showInitialLoader = detailsAsync.isLoading && !_didPopulate;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccountScreenHeader(
                title: 'Bank Details',
                subtitle: 'Add the account where you want to receive payouts.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: showInitialLoader
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const AccountInfoBanner(
                              icon: LucideIcons.shieldCheck,
                              title: 'Your details are protected',
                              message:
                                  'Bank information is encrypted and used only for partner payouts.',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AccountSectionCard(
                              title: 'Account information',
                              child: Column(
                                children: [
                                  AppTextField(
                                    label: 'Account holder name',
                                    hint: 'Name as per bank records',
                                    controller: _holderController,
                                    errorText: _holderError,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    prefixIcon: const Icon(
                                      LucideIcons.user,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppTextField(
                                    label: 'Account number',
                                    hint: 'Enter account number',
                                    controller: _accountController,
                                    keyboardType: TextInputType.number,
                                    errorText: _accountError,
                                    maxLength: 18,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    prefixIcon: const Icon(
                                      LucideIcons.creditCard,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppTextField(
                                    label: 'Confirm account number',
                                    hint: 'Re-enter account number',
                                    controller: _confirmAccountController,
                                    keyboardType: TextInputType.number,
                                    errorText: _confirmAccountError,
                                    maxLength: 18,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    prefixIcon: const Icon(
                                      LucideIcons.checkCircle2,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppTextField(
                                    label: 'IFSC code',
                                    hint: 'e.g. HDFC0001234',
                                    controller: _ifscController,
                                    errorText: _ifscError,
                                    maxLength: 11,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    inputFormatters: [
                                      _UpperCaseTextFormatter(),
                                      FilteringTextInputFormatter.allow(
                                        RegExp('[A-Z0-9]'),
                                      ),
                                    ],
                                    prefixIcon: const Icon(
                                      LucideIcons.landmark,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AccountSectionCard(
                              title: 'UPI (optional)',
                              child: AppTextField(
                                label: 'UPI ID',
                                hint: 'name@bank',
                                controller: _upiController,
                                errorText: _upiError,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(
                                  LucideIcons.indianRupee,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
              ),
              PrimaryCtaButton(
                label: Get.previousRoute == AppRoutes.selfieVerification
                    ? 'Save & continue'
                    : 'Save bank details',
                isLoading: detailsAsync.isLoading && _didPopulate,
                trailingIcon: LucideIcons.check,
                onPressed: detailsAsync.isLoading ? null : _save,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
