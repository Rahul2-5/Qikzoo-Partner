import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/polling/rider_polling_controller.dart';

/// The one always-mounted widget in the app tree — every screen below it is
/// a GetX route that gets fully replaced (`Get.offAllNamed`, see
/// `app_bottom_nav.dart`'s `navigateToTab`) on tab navigation, so this is
/// the only place an app-wide (not screen-scoped) background/foreground
/// signal can live. Its sole job is forwarding resume/pause to
/// [riderPollingControllerProvider], which otherwise has no way to know the
/// app was backgrounded while, say, the Orders tab (not the Dashboard) was
/// on screen — `DashboardHomeScreen`'s own lifecycle observer only exists
/// while that specific screen is mounted.
///
/// Deliberately does not touch location tracking —
/// `riderLocationControllerProvider`'s own foreground/background handling
/// stays exactly where it already was, in `DashboardHomeScreen`.
///
/// Kept as its own widget (wrapped around `GetMaterialApp` in `app.dart`)
/// rather than inlined there so it can be pumped directly in a test with a
/// trivial child, without needing the app's full real route table.
class RiderPollingLifecycleObserver extends ConsumerStatefulWidget {
  const RiderPollingLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RiderPollingLifecycleObserver> createState() =>
      _RiderPollingLifecycleObserverState();
}

class _RiderPollingLifecycleObserverState
    extends ConsumerState<RiderPollingLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final polling = ref.read(riderPollingControllerProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      polling.handleResume();
    } else if (state == AppLifecycleState.paused) {
      polling.handlePause();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
