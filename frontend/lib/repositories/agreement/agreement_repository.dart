import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/agreement/agreement_model.dart';

abstract class AgreementRepository {
  Future<void> acceptAgreement(AgreementModel agreement);
}

class MockAgreementRepository implements AgreementRepository {
  @override
  Future<void> acceptAgreement(AgreementModel agreement) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }
}

final agreementRepositoryProvider = Provider<AgreementRepository>((ref) => MockAgreementRepository());
