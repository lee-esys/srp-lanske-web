import 'app_localizations.dart';

export 'app_localizations.dart';

extension DoublesMatchNavigationLocalizations on AppLocalizations {
  String doublesMatchPositionLabel(int roundNo, int courtNo) {
    return '${teamRoundTitle(roundNo)}$teamMatchGroupSeparator${teamCourtTitle(courtNo)}';
  }

  String doublesProgressPositionLabel(int roundNo, String courtLabel) {
    final courtTitle = teamCourtTitle(0).replaceFirst('0', courtLabel);
    return '${teamRoundTitle(roundNo)}$teamMatchGroupSeparator$courtTitle';
  }

  String get doublesProgressInProgressTitle =>
      doublesMatchStatusInProgressLabel;

  String get doublesProgressNextMatchTitle => nextTeamMatchTitle;

  String get doublesProgressAllCompletedLabel =>
      doublesMatchStatusCompletedLabel;
}
