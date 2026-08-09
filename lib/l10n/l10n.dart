import 'app_localizations.dart';

export 'app_localizations.dart';

extension DoublesMatchNavigationLocalizations on AppLocalizations {
  String doublesMatchPositionLabel(int roundNo, int courtNo) {
    return '${teamRoundTitle(roundNo)}$teamMatchGroupSeparator${teamCourtTitle(courtNo)}';
  }

  String doublesProgressPositionLabel(int roundNo, String courtLabel) {
    return '${teamRoundTitle(roundNo)}$teamMatchGroupSeparator$courtLabel';
  }
}
