import 'app_localizations.dart';

extension SupportMenuLocalizations on AppLocalizations {
  String get supportMenuTitle {
    if (localeName.startsWith('ja')) return 'サポート';
    return 'Support page (Japanese)';
  }

  String get supportMenuSubtitle {
    if (localeName.startsWith('ja')) return 'フィードバックもこちらから';
    return 'Feedback form is linked there';
  }
}
