import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/welcome_kit_illustration.dart';

enum WelcomeKitPlan { fullPayment, threeMonths }

enum WelcomeKitPaymentMethod { upi, card }

typedef WelcomeKitPaymentHandler = Future<bool> Function(
  WelcomeKitPlan plan,
  WelcomeKitPaymentMethod method,
);

class WelcomeKitScreen extends StatefulWidget {
  final WelcomeKitPaymentHandler? onPay;

  const WelcomeKitScreen({super.key, this.onPay});

  @override
  State<WelcomeKitScreen> createState() => _WelcomeKitScreenState();
}

class _WelcomeKitScreenState extends State<WelcomeKitScreen> {
  WelcomeKitPlan _selectedPlan = WelcomeKitPlan.fullPayment;
  WelcomeKitPaymentMethod _paymentMethod = WelcomeKitPaymentMethod.upi;
  bool _isPaying = false;

  int get _amountDue => _selectedPlan == WelcomeKitPlan.fullPayment ? 799 : 267;

  Future<bool> _simulateSuccessfulPayment(
    WelcomeKitPlan _,
    WelcomeKitPaymentMethod __,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return true;
  }

  Future<void> _pay() async {
    if (_isPaying) return;

    setState(() => _isPaying = true);
    final paymentHandler = widget.onPay ?? _simulateSuccessfulPayment;

    try {
      final isSuccessful = await paymentHandler(_selectedPlan, _paymentMethod);
      if (!mounted) return;

      if (isSuccessful) {
        Get.offNamed(AppRoutes.applicationSubmitted);
        return;
      }

      setState(() => _isPaying = false);
      _showPaymentError();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      _showPaymentError();
    }
  }

  void _showPaymentError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment could not be completed. Please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPaying,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 720,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                _Header(
                  canGoBack: !_isPaying,
                  onBack: () => Get.back(),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const WelcomeKitIllustration(),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Your Welcome Kit is ready',
                          style: AppTypography.h1.copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Everything you need to start delivering with confidence.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _KitContents(),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Choose a payment plan', style: AppTypography.h2),
                        const SizedBox(height: AppSpacing.sm),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fullPaymentPlan = _PlanCard(
                              key: const Key('full-payment-plan'),
                              title: 'Pay in full',
                              amount: '₹799',
                              subtitle: 'One-time payment',
                              badge: 'SIMPLE',
                              isSelected:
                                  _selectedPlan == WelcomeKitPlan.fullPayment,
                              onTap: () => setState(() =>
                                  _selectedPlan = WelcomeKitPlan.fullPayment),
                            );
                            final threeMonthPlan = _PlanCard(
                              key: const Key('three-month-plan'),
                              title: 'Pay over 3 months',
                              amount: '₹267 today',
                              subtitle:
                                  'Then ₹266/month for 2 months • ₹799 total',
                              badge: 'FLEXIBLE',
                              isSelected:
                                  _selectedPlan == WelcomeKitPlan.threeMonths,
                              onTap: () => setState(() =>
                                  _selectedPlan = WelcomeKitPlan.threeMonths),
                            );

                            if (constraints.maxWidth >= 600) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: fullPaymentPlan),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(child: threeMonthPlan),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                fullPaymentPlan,
                                const SizedBox(height: AppSpacing.sm),
                                threeMonthPlan,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Pay securely with', style: AppTypography.h2),
                        const SizedBox(height: AppSpacing.sm),
                        _PaymentMethodCard(
                          key: const Key('upi-payment-method'),
                          icon: LucideIcons.smartphone,
                          title: 'UPI',
                          subtitle: 'Google Pay, PhonePe, Paytm & more',
                          isSelected:
                              _paymentMethod == WelcomeKitPaymentMethod.upi,
                          onTap: () => setState(() =>
                              _paymentMethod = WelcomeKitPaymentMethod.upi),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PaymentMethodCard(
                          key: const Key('card-payment-method'),
                          icon: LucideIcons.creditCard,
                          title: 'Credit or debit card',
                          subtitle: 'Visa, Mastercard and RuPay',
                          isSelected:
                              _paymentMethod == WelcomeKitPaymentMethod.card,
                          onTap: () => setState(() =>
                              _paymentMethod = WelcomeKitPaymentMethod.card),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.background.withValues(alpha: 0.92),
                        offset: const Offset(0, -12),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      PrimaryCtaButton(
                        label: 'Pay ₹$_amountDue securely',
                        trailingIcon: LucideIcons.lock,
                        isLoading: _isPaying,
                        onPressed: _pay,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.shieldCheck,
                            size: 15,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'Payments are encrypted and securely processed',
                              textAlign: TextAlign.center,
                              style:
                                  AppTypography.caption.copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool canGoBack;
  final VoidCallback onBack;

  const _Header({required this.canGoBack, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButtonCustom(
          icon: LucideIcons.arrowLeft,
          onPressed: canGoBack ? onBack : null,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                color: AppColors.success,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Secure checkout',
                style: AppTypography.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KitContents extends StatelessWidget {
  const _KitContents();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: AppShadows.control,
      ),
      child: const Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          _KitContentItem(
              icon: LucideIcons.packageCheck, label: 'Delivery bag'),
          _KitContentItem(icon: LucideIcons.shirt, label: 'Partner T-shirt'),
          _KitContentItem(
              icon: LucideIcons.badgeCheck, label: 'Training support'),
        ],
      ),
    );
  }
}

class _KitContentItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _KitContentItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondaryBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: AppColors.secondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.bodyMedium),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final String badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $amount, $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.quick),
            curve: AppMotion.enter,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 130),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF2F3FF) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: isSelected ? AppColors.secondary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? AppShadows.control : const [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondaryBg
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(title, style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        amount,
                        style: AppTypography.numericMd.copyWith(
                          color: AppColors.primary,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _SelectionIndicator(isSelected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.quick),
            curve: AppMotion.enter,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: isSelected ? AppColors.secondary : AppColors.border,
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondaryBg
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AppTypography.bodyMedium),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _SelectionIndicator(isSelected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool isSelected;

  const _SelectionIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.quick),
      curve: AppMotion.enter,
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.secondary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.secondary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}

@Preview(
  name: 'Welcome Kit checkout',
  group: 'Partner registration',
  size: Size(390, 844),
)
Widget welcomeKitScreenPreview() {
  return GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const WelcomeKitScreen(),
  );
}
