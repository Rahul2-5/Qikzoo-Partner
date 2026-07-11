/// Placeholder REST client. Not wired to anything yet — every repository
/// currently uses a Mock* implementation instead. When a real backend
/// exists, give this class real HTTP methods and swap the Provider bodies
/// in repositories/*/*_repository.dart from Mock* to a Rest* implementation
/// that depends on this client.
class ApiClient {
  final String baseUrl;

  const ApiClient({this.baseUrl = ''});
}
