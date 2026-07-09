import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/authentication/auth_repository.dart';
import '../../models/authentication/auth_session_model.dart';

/// UI state: the phone number currently being entered/verified.
final phoneNumberUiProvider = StateProvider<String>((ref) => '');

/// Domain state: the authenticated session.
class AuthSessionNotifier extends AsyncNotifier<AuthSessionModel> {
  @override
  Future<AuthSessionModel> build() async => AuthSessionModel.empty;

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyOtp(phoneNumber, otp),
    );
  }
}

final authSessionProvider = AsyncNotifierProvider<AuthSessionNotifier, AuthSessionModel>(
  AuthSessionNotifier.new,
);
