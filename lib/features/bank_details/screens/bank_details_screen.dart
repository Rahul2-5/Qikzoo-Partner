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
import '../../../shared/widgets/misc/loading_skeleton.dart';
import '../../profile/widgets/account_screen_components.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final _holderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();

  bool _didPopulate = false;
  String? _holderError;
  String? _bankNameError;
  String? _accountError;
  String? _confirmAccountError;
  String? _ifscError;

  @override
  void dispose() {
    _holderController.dispose();
    _bankNameController.dispose();
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _populate(BankDetailsModel? details) {
    if (_didPopulate) return;
    _didPopulate = true;
    if (details == null) return;
    _holderController.text = details.accountHolderName;
    _bankNameController.text = details.bankName;
    _ifscController.text = details.ifsc;
    // The backend never returns the real account number, only a masked
    // form — the rider must re-enter it to change bank details.
  }

  bool _validate() {
    final holder = _holderController.text.trim();
    final bankName = _bankNameController.text.trim();
    final account = _accountController.text.trim();
    final confirmation = _confirmAccountController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();

    setState(() {
      _holderError = holder.length < 3 ? 'Enter the account holder name' : null;
      _bankNameError = bankName.length < 2 ? 'Enter your bank name' : null;
      _accountError = account.length < 9 || account.length > 18
          ? 'Enter a valid account number'
          : null;
      _confirmAccountError =
          confirmation != account ? 'Account numbers do not match' : null;
      _ifscError = Validators.isValidIfsc(ifsc)
          ? null
          : 'Enter a valid 11-character IFSC code';
    });

    return [
      _holderError,
      _bankNameError,
      _accountError,
      _confirmAccountError,
      _ifscError,
    ].every((error) => error == null);
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final accountNumber = _accountController.text.trim();
    final details = BankDetailsModel(
      accountHolderName: _holderController.text.trim(),
      accountNumberMasked: null,
      ifsc: _ifscController.text.trim().toUpperCase(),
      bankName: _bankNameController.text.trim(),
    );
    await ref
        .read(bankDetailsProvider.notifier)
        .save(details, accountNumber: accountNumber);
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
                    ? const PageLoadingShimmer(
                        padding: EdgeInsets.zero,
                        itemCount: 2,
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            AccountInfoBanner(
                              icon: LucideIcons.shieldCheck,
                              title: detailsAsync.valueOrNull?.accountNumberMasked !=
                                      null
                                  ? 'On file: ${detailsAsync.valueOrNull!.accountNumberMasked}'
                                  : 'Your details are protected',
                              message: detailsAsync.valueOrNull?.accountNumberMasked !=
                                      null
                                  ? 'Re-enter your account number below to change it.'
                                  : 'Bank information is encrypted and used only for partner payouts.',
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
                                    label: 'Bank name',
                                    hint: 'e.g. HDFC Bank',
                                    controller: _bankNameController,
                                    errorText: _bankNameError,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    prefixIcon: const Icon(
                                      LucideIcons.landmark,
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
