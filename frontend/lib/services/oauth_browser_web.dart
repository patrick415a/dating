import 'package:web/web.dart';

const _verifierKey = 'dating.oauthVerifier';

void beginBrowserLogin(String authorizationUrl, String verifier) {
  window.sessionStorage.setItem(_verifierKey, verifier);
  window.location.assign(authorizationUrl);
}

String? takeBrowserLoginVerifier() {
  final url = URL(window.location.href);
  for (final key in ['code', 'state', 'error', 'error_description', 'scope', 'authuser', 'hd', 'prompt']) {
    url.searchParams.delete(key);
  }
  window.history.replaceState(window.history.state, '', url.href);

  try {
    final verifier = window.sessionStorage.getItem(_verifierKey);
    window.sessionStorage.removeItem(_verifierKey);
    return verifier;
  } catch (_) {
    return null;
  }
}
