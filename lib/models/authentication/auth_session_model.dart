import 'package:equatable/equatable.dart';

class AuthSessionModel extends Equatable {
  final String partnerId;
  final String token;
  final bool isAuthenticated;

  const AuthSessionModel({
    required this.partnerId,
    required this.token,
    required this.isAuthenticated,
  });

  static const empty = AuthSessionModel(partnerId: '', token: '', isAuthenticated: false);

  @override
  List<Object?> get props => [partnerId, token, isAuthenticated];
}
