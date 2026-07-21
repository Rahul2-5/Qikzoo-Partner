enum AuthFlow { login, signUp }

AuthFlow authFlowFromRoute(String? value) {
  return value == 'signup' ? AuthFlow.signUp : AuthFlow.login;
}

String authFlowRoute(
  String route,
  AuthFlow flow, {
  String? phone,
}) {
  final value = flow == AuthFlow.signUp ? 'signup' : 'login';
  final query = <String, String>{'flow': value};
  if (phone != null && phone.trim().isNotEmpty) {
    query['phone'] = phone.trim();
  }
  return Uri(path: route, queryParameters: query).toString();
}
