final Map<String, String> _localValues = <String, String>{};

String? readBrowserValue(String key) => _localValues[key];

void writeBrowserValue(String key, String value) {
  _localValues[key] = value;
}

void removeBrowserValue(String key) {
  _localValues.remove(key);
}
