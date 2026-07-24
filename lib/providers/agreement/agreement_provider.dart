import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/agreement/agreement_repository.dart';
import '../../models/agreement/agreement_model.dart';

class AgreementNotifier extends Notifier<AgreementModel> {
  @override
  AgreementModel build() => const AgreementModel(
        termsAccepted: false,
        privacyAccepted: false,
        partnerAgreementAccepted: false,
      );

  void toggleTerms(bool value) => state = AgreementModel(
        termsAccepted: value,
        privacyAccepted: state.privacyAccepted,
        partnerAgreementAccepted: state.partnerAgreementAccepted,
      );

  void togglePrivacy(bool value) => state = AgreementModel(
        termsAccepted: state.termsAccepted,
        privacyAccepted: value,
        partnerAgreementAccepted: state.partnerAgreementAccepted,
      );

  void togglePartnerAgreement(bool value) => state = AgreementModel(
        termsAccepted: state.termsAccepted,
        privacyAccepted: state.privacyAccepted,
        partnerAgreementAccepted: value,
      );

  Future<void> submit() async {
    if (!state.allAccepted) return;
    await ref.read(agreementRepositoryProvider).acceptAgreement(state);
  }
}

final agreementProvider = NotifierProvider<AgreementNotifier, AgreementModel>(AgreementNotifier.new);
