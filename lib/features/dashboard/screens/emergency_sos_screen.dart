import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/location/rider_location_provider.dart';
import '../../../providers/profile/profile_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class EmergencySosScreen extends ConsumerStatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  ConsumerState<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends ConsumerState<EmergencySosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  static const String emergencyNumber112 = '112';
  static const String qikzooHelplineNumber = '+919876543210';
  static const String policeNumber = '100';
  static const String ambulanceNumber = '108';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not launch phone dialer for $phone');
    }
  }

  Future<void> _confirmAndCall(
      String name, String number, String description) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.phoneCall,
                  color: AppColors.error,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirm $name Call',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.phone, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Dial $name ($number)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _makeCall(number);
    }
  }

  Future<void> _shareLiveLocation() async {
    final location = ref.read(riderLocationControllerProvider);
    final lat = location.lastLat;
    final lng = location.lastLng;

    final locationUrl = (lat != null && lng != null)
        ? 'https://maps.google.com/?q=$lat,$lng'
        : 'Location unavailable';

    final text =
        'EMERGENCY: I am a Qikzoo Delivery Partner and need urgent assistance. My live location: $locationUrl';

    final encodedBody = Uri.encodeComponent(text);
    final smsUri = Uri.parse('sms:?body=$encodedBody');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppSnackBar.success(
        context,
        'Live location text copied! Paste it in your messaging app.',
      );
    }
  }

  void _showSafetyInstructions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Safety & First-Aid Guidelines',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _buildSafetyStep(
              number: '1',
              title: 'Move to a Safe Spot',
              description:
                  'If involved in a road incident, move to the road shoulder away from oncoming traffic immediately.',
            ),
            _buildSafetyStep(
              number: '2',
              title: 'Assess Injuries & Check Surroundings',
              description:
                  'Check yourself and others for visible injuries. Do not attempt to move heavily injured individuals without medical help.',
            ),
            _buildSafetyStep(
              number: '3',
              title: 'Call 112 / 108 Emergency Medical',
              description:
                  'Dial 112 for national emergency or 108 for immediate medical ambulance dispatch.',
            ),
            _buildSafetyStep(
              number: '4',
              title: 'Inform Qikzoo Support & Family',
              description:
                  'Notify the Qikzoo 24x7 Safety team and your saved emergency contact so our field operations can assist.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSafetyStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Emergency Assistance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),

                // Pulsing SOS Circle with Tap Confirmation
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple 2
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final progress =
                                (_pulseController.value + 0.5) % 1.0;
                            return Container(
                              width: 110 + (progress * 80),
                              height: 110 + (progress * 80),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFDC2626).withValues(
                                  alpha: 0.12 * (1.0 - progress),
                                ),
                              ),
                            );
                          },
                        ),
                        // Ripple 1
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final progress = _pulseController.value;
                            return Container(
                              width: 110 + (progress * 80),
                              height: 110 + (progress * 80),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFDC2626).withValues(
                                  alpha: 0.22 * (1.0 - progress),
                                ),
                              ),
                            );
                          },
                        ),
                        // Central SOS Core Button
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _confirmAndCall(
                              'National Emergency',
                              emergencyNumber112,
                              'Instant connection to Police, Ambulance, and Fire services.',
                            ),
                            child: Ink(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFB91C1C),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDC2626)
                                        .withValues(alpha: 0.45),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'SOS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'TAP TO CALL 112',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title and Warning
                const Text(
                  'Are you in an emergency?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use this for accidents, medical emergencies, or on-duty safety hazards.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Action Cards (Share Location via SMS & Report Accident)
                Row(
                  children: [
                    Expanded(
                      child: _buildSecondaryActionCard(
                        icon: LucideIcons.share2,
                        title: 'Share Location',
                        subtitle: 'Pick contact & send SMS',
                        color: AppColors.primary,
                        onTap: _shareLiveLocation,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSecondaryActionCard(
                        icon: LucideIcons.shieldAlert,
                        title: 'Report Accident',
                        subtitle: 'Notify Support team',
                        color: const Color(0xFFD97706),
                        onTap: () => Get.toNamed(AppRoutes.support),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Section Label
                const Text(
                  'Emergency Helplines',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // National Emergency (112)
                _buildCallButton(
                  icon: LucideIcons.alertOctagon,
                  title: 'National Emergency Helpline',
                  subtitle: 'Dial 112 (Police, Ambulance & Fire combined)',
                  color: const Color(0xFFDC2626),
                  isPrimary: true,
                  onTap: () => _confirmAndCall(
                    'National Emergency',
                    emergencyNumber112,
                    'Instant connection to Police, Ambulance, and Fire services.',
                  ),
                ),
                const SizedBox(height: 10),

                // Police (100)
                _buildCallButton(
                  icon: LucideIcons.shield,
                  title: 'Call Police (100)',
                  subtitle: 'Direct line to local Police control room',
                  color: const Color(0xFF2563EB),
                  isPrimary: false,
                  onTap: () => _confirmAndCall(
                    'Police',
                    policeNumber,
                    'Direct connection to local Police control room.',
                  ),
                ),
                const SizedBox(height: 10),

                // Ambulance (108)
                _buildCallButton(
                  icon: LucideIcons.activity,
                  title: 'Call Ambulance (108)',
                  subtitle: 'Emergency medical assistance and hospital ambulance',
                  color: const Color(0xFFEA580C),
                  isPrimary: false,
                  onTap: () => _confirmAndCall(
                    'Ambulance',
                    ambulanceNumber,
                    'Emergency medical assistance and hospital ambulance.',
                  ),
                ),
                const SizedBox(height: 10),

                // Qikzoo 24x7 Safety Helpline
                _buildCallButton(
                  icon: LucideIcons.headphones,
                  title: 'Contact Qikzoo Safety Team',
                  subtitle: '24x7 Dedicated Partner Support',
                  color: const Color(0xFF4F46E5),
                  isPrimary: false,
                  onTap: () => _confirmAndCall(
                    'Qikzoo Safety Helpline',
                    qikzooHelplineNumber,
                    'Direct line to Qikzoo safety incident response team.',
                  ),
                ),
                const SizedBox(height: 16),

                // Saved Emergency Contact Card
                profileAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (profile) {
                    final hasContact =
                        profile.emergencyContactPhone != null &&
                            profile.emergencyContactPhone!.isNotEmpty;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.userCheck,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasContact
                                      ? (profile.emergencyContactName ??
                                          'Saved Emergency Contact')
                                      : 'No Emergency Contact Added',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasContact
                                      ? profile.emergencyContactPhone!
                                      : 'Add family/friend contact for quick reach',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasContact)
                            IconButton(
                              icon: const Icon(LucideIcons.phone,
                                  color: Color(0xFF0D8538), size: 20),
                              onPressed: () => _confirmAndCall(
                                profile.emergencyContactName ??
                                    'Emergency Contact',
                                profile.emergencyContactPhone!,
                                'Calling your saved emergency contact.',
                              ),
                              tooltip: 'Call Emergency Contact',
                            )
                          else
                            TextButton(
                              onPressed: () =>
                                  Get.toNamed(AppRoutes.emergencyContact),
                              child: const Text('Add'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Safety Instructions button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: _showSafetyInstructions,
                  icon: const Icon(LucideIcons.bookOpen,
                      size: 16, color: AppColors.textPrimary),
                  label: const Text(
                    'Safety & First Aid Instructions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: isPrimary ? color : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? color.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isPrimary ? Colors.white : color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          isPrimary ? Colors.white : const Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF6B7280),
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.phoneForwarded,
              size: 16,
              color: isPrimary ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
