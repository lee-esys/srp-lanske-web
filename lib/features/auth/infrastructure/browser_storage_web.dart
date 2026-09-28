import 'package:web/web.dart' as web;

String? readBrowserValue(String key) {
  return web.window.localStorage.getItem(key);
}

void writeBrowserValue(String key, String value) {
  web.window.localStorage.setItem(key, value);
}

void removeBrowserValue(String key) {
  web.window.localStorage.removeItem(key);
}
