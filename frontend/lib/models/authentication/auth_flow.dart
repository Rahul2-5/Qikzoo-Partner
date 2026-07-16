enum AuthFlow { login, signUp }

AuthFlow authFlowFromRoute(String? value) {
  return value == 'signup' ? AuthFlow.signUp : AuthFlow.login;
}

String authFlowRoute(String route, AuthFlow flow) {
  final value = flow == AuthFlow.signUp ? 'signup' : 'login';
  return '$route?flow=$value';
}
