import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/capture_button.dart';
import '../widgets/face_overlay.dart';
import '../widgets/selfie_camera_preview.dart';
import '../widgets/status_card.dart';
import '../services/selfie_image_processor.dart';

const _qikzooNavy = Color(0xFF162B4D);

typedef CameraListLoader = Future<List<CameraDescription>> Function();
typedef SelfieCameraControllerBuilder = CameraController Function(
  CameraDescription camera,
);

/// Production-quality, frontend-only selfie capture experience.
///
/// This screen intentionally performs no face detection, OCR, ML processing,
/// networking, or upload. A successful capture simply returns the local image
/// path to the caller.
class SelfieCameraCaptureScreen extends StatefulWidget {
  const SelfieCameraCaptureScreen({
    super.key,
    this.cameraListLoader = availableCameras,
    this.controllerBuilder,
  });

  final CameraListLoader cameraListLoader;

  /// Optional injection point used by tests and alternative camera hosts.
  final SelfieCameraControllerBuilder? controllerBuilder;

  @override
  State<SelfieCameraCaptureScreen> createState() =>
      _SelfieCameraCaptureScreenState();
}

class _SelfieCameraCaptureScreenState extends State<SelfieCameraCaptureScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _primary = AppColors.primary;
  static const _background = AppColors.background;
  static const _textSecondary = AppColors.textSecondary;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _cameraScaleAnimation;

  CameraController? _cameraController;
  Future<void> _cameraQueue = Future<void>.value();

  bool _isLifecycleActive = true;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _entranceStarted = false;
  String? _cameraError;
  String? _captureError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
    );
    _cameraScaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.12, 1, curve: Curves.easeOutBack),
      ),
    );
    _scheduleCameraOperation(_initializeCamera);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isLifecycleActive = true;
        if (mounted) {
          setState(() => _isInitializing = true);
        }
        _scheduleCameraOperation(_initializeCamera);
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _isLifecycleActive = false;
        final controller = _cameraController;
        if (mounted) {
          setState(() {
            _cameraController = null;
            _isInitializing = true;
          });
        }
        _scheduleCameraOperation(() => _disposeController(controller));
        return;
    }
  }

  void _scheduleCameraOperation(Future<void> Function() operation) {
    final next = _cameraQueue.then((_) => operation());
    _cameraQueue = next.catchError((Object _) {});
  }

  Future<void> _initializeCamera() async {
    if (!mounted ||
        !_isLifecycleActive ||
        _cameraController?.value.isInitialized == true) {
      return;
    }

    if (mounted) {
      setState(() {
        _isInitializing = true;
        _cameraError = null;
      });
    }

    CameraController? candidate;
    try {
      final cameras = await widget.cameraListLoader();
      if (cameras.isEmpty) {
        throw CameraException(
          'camera_not_found',
          'No camera is available on this device.',
        );
      }

      final frontCameras = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.front)
          .toList();
      if (frontCameras.isEmpty) {
        throw CameraException(
          'front_camera_not_found',
          'No front camera is available on this device.',
        );
      }
      final frontCamera = frontCameras.first;
      candidate = widget.controllerBuilder?.call(frontCamera) ??
          CameraController(
            frontCamera,
            ResolutionPreset.medium,
            enableAudio: false,
          );
      await candidate.initialize();

      if (!mounted || !_isLifecycleActive) {
        await candidate.dispose();
        return;
      }

      setState(() {
        _cameraController = candidate;
        _isInitializing = false;
        _cameraError = null;
      });
    } on CameraException catch (error) {
      await _disposeController(candidate);
      if (mounted && _isLifecycleActive) {
        setState(() {
          _isInitializing = false;
          _cameraError = _friendlyCameraError(error);
        });
      }
    } catch (_) {
      await _disposeController(candidate);
      if (mounted && _isLifecycleActive) {
        setState(() {
          _isInitializing = false;
          _cameraError = 'The camera could not be started. Please try again.';
        });
      }
    }
  }

  Future<void> _disposeController(CameraController? controller) async {
    if (controller == null) return;
    try {
      await controller.dispose();
    } on CameraException {
      // Disposal failures do not require a user-facing error.
    }
  }

  String _friendlyCameraError(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' =>
        'Camera access is required. Enable it in your device settings and try again.',
      'front_camera_not_found' =>
        'A front camera is required to take your shift selfie.',
      _ => 'The camera could not be started. Please try again.',
    };
  }

  void _retryCamera() {
    if (_isInitializing) return;
    HapticFeedback.selectionClick();
    _scheduleCameraOperation(_initializeCamera);
  }

  Future<void> _captureSelfie() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _captureError = null;
    });
    unawaited(HapticFeedback.mediumImpact());

    try {
      final image = await controller.takePicture();
      final selfiePath =
          await SelfieImageProcessor.prepareForUpload(image.path);
      if (mounted) Navigator.of(context).pop(selfiePath);
    } on CameraException {
      if (mounted) {
        setState(() {
          _captureError = 'We could not capture your selfie. Please try again.';
        });
      }
    } on FileSystemException {
      if (mounted) {
        setState(() {
          _captureError = 'We could not prepare your selfie. Please try again.';
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _captureError = 'We could not prepare your selfie. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _close() {
    HapticFeedback.selectionClick();
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isLifecycleActive = false;
    _entranceController.dispose();
    final controller = _cameraController;
    _cameraController = null;
    unawaited(_disposeController(controller));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 480,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;

              // Column fills the exact available height: fixed-height header
              // + Expanded camera circle (which fills ALL of its region,
              // no shrink factor) + a bottom section sized only to what its
              // content actually needs. Nothing scrolls, nothing floats in
              // unclaimed space.
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: compact ? AppSpacing.xs : AppSpacing.sm,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _Header(onBack: _close, compact: compact),
                      SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                      Expanded(
                        child: Center(
                          child: ScaleTransition(
                            scale: _cameraScaleAnimation,
                            child: LayoutBuilder(
                              builder: (context, inner) {
                                final guideSize = math
                                    .min(inner.maxWidth, inner.maxHeight)
                                    .clamp(180.0, 420.0)
                                    .toDouble();
                                return _buildCameraGuide(guideSize);
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                      _buildBottomSection(context, compact: compact),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCameraGuide(double guideSize) {
    final controller = _cameraController;
    final preview = switch ((controller, _cameraError)) {
      (_, final String error) => _CameraErrorView(
          key: const ValueKey('camera-error'),
          message: error,
          onRetry: _retryCamera,
        ),
      (final CameraController readyController, _)
          when readyController.value.isInitialized =>
        SelfieCameraPreview(
          key: ValueKey(readyController.description.name),
          controller: readyController,
        ),
      _ => const _CameraLoadingView(key: ValueKey('camera-loading')),
    };

    return Semantics(
      label: 'Front camera selfie frame',
      image: true,
      child: SizedBox.square(
        dimension: guideSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.18),
                blurRadius: 34,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 20,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: const Color(0xFF0F172A),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1.04, end: 1)
                              .animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: preview,
                  ),
                ),
                const FaceOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, {required bool compact}) {
    final status = switch ((_isCapturing, _cameraError, _captureError)) {
      (true, _, _) => const (
          message: 'Capturing your selfie…',
          tone: SelfieStatusTone.busy,
        ),
      (_, final String error, _) => (
          message: error,
          tone: SelfieStatusTone.error,
        ),
      (_, _, final String error) => (
          message: error,
          tone: SelfieStatusTone.error,
        ),
      _ => const (
          message: 'Align your face inside the frame',
          tone: SelfieStatusTone.neutral,
        ),
    };
    final cameraReady =
        _cameraController?.value.isInitialized == true && _cameraError == null;

    // A single row puts the capture control and Cancel side by side, at a
    // fixed height, so this section never grows to eat the camera's space
    // and never needs its own scroll.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelfieStatusCard(message: status.message, tone: status.tone),
        SizedBox(height: compact ? 10 : 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              child: TextButton(
                onPressed: _close,
                style: TextButton.styleFrom(
                  foregroundColor: _textSecondary,
                  minimumSize: const Size(0, 44),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            CaptureButton(
              onPressed: cameraReady ? _captureSelfie : null,
              isLoading: _isCapturing,
            ),
            const SizedBox(width: AppSpacing.lg),
            const SizedBox(width: 72),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.shieldCheck, size: 13, color: _primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Secure Face Verification',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: _textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Back button + title, both vertically centered against an explicit
/// height so the title's line box always has room for its ascenders —
/// no clipping — and a [FittedBox] guarantees the text scales down rather
/// than truncating on narrow screens instead of wrapping/ellipsis.
class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.compact});

  final VoidCallback onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButtonCustom(
              icon: LucideIcons.arrowLeft,
              tooltip: 'Back',
              onPressed: onBack,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Face verification',
                    maxLines: 1,
                    style: AppTypography.h2.copyWith(
                      color: _qikzooNavy,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      fontSize: compact ? 17 : 19,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _CameraLoadingView extends StatelessWidget {
  const _CameraLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF0F172A),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 240;
          return Center(
            child: Padding(
              padding: EdgeInsets.all(compact ? 18 : 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.cameraOff,
                    color: Colors.white,
                    size: compact ? 24 : 28,
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Text(
                    message,
                    maxLines: compact ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: compact ? 11 : 12.5,
                      height: compact ? 1.25 : 1.35,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 10),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: Size(72, compact ? 36 : 44),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}