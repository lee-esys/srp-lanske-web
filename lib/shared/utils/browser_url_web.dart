import 'package:web/web.dart' as web;

void replaceUrl(String url) {
  web.window.history.replaceState(null, '', url);
}

void reloadPage() {
  web.window.location.reload();
}
