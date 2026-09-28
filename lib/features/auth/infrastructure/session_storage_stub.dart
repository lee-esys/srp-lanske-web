final Map<String, String> _sessionValues = <String, String>{};

String? readSessionValue(String key) => _sessionValues[key];

void writeSessionValue(String key, String value) {
  _sessionValues[key] = value;
}

void removeSessionValue(String key) {
  _sessionValues.remove(key);
}
