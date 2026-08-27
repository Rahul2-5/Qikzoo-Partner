import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../models/orders/delivery_payment_session.dart';
import '../../repositories/orders/rider_orders_repository.dart';

class DeliveryPaymentState {
  const DeliveryPaymentState({
    required this.status,
    required this.lastConfirmedStatus,
    required this.session,
    required this.connectionMessage,
    required this.retryAttempt,
  });

  const DeliveryPaymentState.initial()
      : status = DeliveryPaymentStatus.initial,
        lastConfirmedStatus = DeliveryPaymentStatus.initial,
        session = null,
        connectionMessage = null,
        retryAttempt = 0;

  final DeliveryPaymentStatus status;
  final DeliveryPaymentStatus lastConfirmedStatus;
  final DeliveryPaymentSession? session;
  final String? connectionMessage;
  final int retryAttempt;

  bool get isPendingSafely =>
      status == DeliveryPaymentStatus.pending ||
      (status == DeliveryPaymentStatus.connectionError &&
          lastConfirmedStatus == DeliveryPaymentStatus.pending);

  bool get isTerminal => switch (status) {
        DeliveryPaymentStatus.success ||
        DeliveryPaymentStatus.failed ||
        DeliveryPaymentStatus.expired ||
        DeliveryPaymentStatus.cancelled =>
          true,
        _ => false,
      };

  DeliveryPaymentState copyWith({
    DeliveryPaymentStatus? status,
    DeliveryPaymentStatus? lastConfirmedStatus,
    DeliveryPaymentSession? session,
    bool clearSession = false,
    String? connectionMessage,
    bool clearConnectionMessage = false,
    int? retryAttempt,
  }) {
    return DeliveryPaymentState(
      status: status ?? this.status,
      lastConfirmedStatus: lastConfirmedStatus ?? this.lastConfirmedStatus,
      session: clearSession ? null : session ?? this.session,
      connectionMessage: clearConnectionMessage
          ? null
          : connectionMessage ?? this.connectionMessage,
      retryAttempt: retryAttempt ?? this.retryAttempt,
    );
  }
}

final deliveryPaymentPollIntervalProvider =
    Provider<Duration>((_) => const Duration(seconds: 3));

class DeliveryPaymentNotifier
    extends AutoDisposeFamilyNotifier<DeliveryPaymentState, String> {
  Timer? _pollTimer;
  Future<void>? _openInFlight;
  bool _statusInFlight = false;
  bool _sessionCreationInFlight = false;
  bool _paused = false;
  bool _disposed = false;
  late String _riderOrderId;

  @override
  DeliveryPaymentState build(String arg) {
    _riderOrderId = arg;
    ref.onDispose(() {
      _disposed = true;
      _pollTimer?.cancel();
    });
    return const DeliveryPaymentState.initial();
  }

  Future<void> open() {
    return _openInFlight ??= _openExistingOrCreate().whenComplete(() {
      _openInFlight = null;
    });
  }

  Future<void> _openExistingOrCreate() async {
    if (state.status == DeliveryPaymentStatus.success) return;
    state = state.copyWith(
      status: DeliveryPaymentStatus.creatingSession,
      clearConnectionMessage: true,
    );
    try {
      final existing = await _readAuthoritativeSession();
      if (_disposed) return;
      _applySession(existing);
    } on ApiException catch (error) {
      if (_disposed) return;
      if (error.statusCode == 404) {
        await _createSession();
      } else {
        _handleConnectionError();
      }
    } catch (_) {
      if (!_disposed) _handleConnectionError();
    }
  }

  Future<void> checkStatus() async {
    if (_statusInFlight || _disposed) return;
    final session = state.session;
    if (session == null) {
      await open();
      return;
    }
    _statusInFlight = true;
    try {
      final latest = await _readAuthoritativeSession();
      if (!_disposed) _applySession(latest);
    } catch (_) {
      if (!_disposed) _handleConnectionError();
    } finally {
      _statusInFlight = false;
    }
  }

  Future<void> regenerate() async {
    if (_sessionCreationInFlight || _statusInFlight || _disposed) return;

    // A connection warning can hide a customer payment. Resolve the existing
    // session first and never rotate it optimistically.
    if (state.status == DeliveryPaymentStatus.connectionError ||
        state.status == DeliveryPaymentStatus.pending ||
        state.status == DeliveryPaymentStatus.success) {
      await checkStatus();
      return;
    }

    state = state.copyWith(
      status: DeliveryPaymentStatus.creatingSession,
      clearConnectionMessage: true,
    );
    try {
      final latest = await _readAuthoritativeSession();
      if (_disposed) return;
      if (latest.status == DeliveryPaymentStatus.pending ||
          latest.status == DeliveryPaymentStatus.success ||
          latest.status == DeliveryPaymentStatus.connectionError) {
        _applySession(latest);
        return;
      }
      await _createSession();
    } on ApiException catch (error) {
      if (_disposed) return;
      if (error.statusCode == 404) {
        await _createSession();
      } else {
        _handleConnectionError();
      }
    } catch (_) {
      if (!_disposed) _handleConnectionError();
    }
  }

  void pause() {
    _paused = true;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void resume() {
    if (_disposed) return;
    _paused = false;
    unawaited(checkStatus());
  }

  Future<DeliveryPaymentSession> _readAuthoritativeSession() async {
    final repository = ref.read(riderOrdersRepositoryProvider);
    var session = await repository.getPaymentSession(_riderOrderId);

    // The current backend commits EXPIRED during the first elapsed status
    // request but may return its pre-update row. One immediate re-read makes
    // the response authoritative without ever creating a replacement.
    if (session.status == DeliveryPaymentStatus.pending && session.hasExpired) {
      session = await repository.getPaymentSession(_riderOrderId);
    }
    return session;
  }

  Future<void> _createSession() async {
    if (_sessionCreationInFlight || _disposed) return;
    _sessionCreationInFlight = true;
    state = state.copyWith(
      status: DeliveryPaymentStatus.creatingSession,
      clearConnectionMessage: true,
    );
    try {
      final session = await ref
          .read(riderOrdersRepositoryProvider)
          .createPaymentSession(_riderOrderId);
      if (!_disposed) _applySession(session);
    } catch (_) {
      if (!_disposed) _handleConnectionError();
    } finally {
      _sessionCreationInFlight = false;
    }
  }

  void _applySession(DeliveryPaymentSession session) {
    final status = session.status;
    state = DeliveryPaymentState(
      status: status,
      lastConfirmedStatus: status == DeliveryPaymentStatus.connectionError
          ? state.lastConfirmedStatus
          : status,
      session: session,
      connectionMessage: status == DeliveryPaymentStatus.connectionError
          ? 'We could not verify the latest payment status.'
          : null,
      retryAttempt: 0,
    );
    if (status == DeliveryPaymentStatus.pending) {
      _schedulePoll(ref.read(deliveryPaymentPollIntervalProvider));
    } else if (status == DeliveryPaymentStatus.connectionError) {
      _schedulePoll(const Duration(seconds: 3));
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _handleConnectionError() {
    final retryAttempt = state.retryAttempt + 1;
    state = state.copyWith(
      status: DeliveryPaymentStatus.connectionError,
      connectionMessage:
          'Connection interrupted. The payment status is unchanged.',
      retryAttempt: retryAttempt,
    );
    final seconds = (3 * retryAttempt).clamp(3, 15);
    _schedulePoll(Duration(seconds: seconds));
  }

  void _schedulePoll(Duration delay) {
    _pollTimer?.cancel();
    if (_paused || _disposed || state.isTerminal) return;
    _pollTimer = Timer(delay, () {
      _pollTimer = null;
      unawaited(checkStatus());
    });
  }
}

final deliveryPaymentProvider = NotifierProvider.autoDispose
    .family<DeliveryPaymentNotifier, DeliveryPaymentState, String>(
  DeliveryPaymentNotifier.new,
);
