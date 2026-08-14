import 'app_localizations.dart';

export 'app_localizations.dart';

extension DoublesMatchNavigationLocalizations on AppLocalizations {
  String doublesMatchPositionLabel(int roundNo, int courtNo) {
    return '${teamRoundTitle(roundNo)}$teamMatchGroupSeparator${teamCourtTitle(courtNo)}';
  }

  String doublesProgressPositionLabel(int roundNo, String courtLabel) {
    return '${teamRoundTitle(roundNo)}$teamMatchGroupSeparator$courtLabel';
  }

  String get doublesProgressInProgressTitle =>
      doublesMatchStatusInProgressLabel;

  String get doublesProgressNextMatchTitle => nextTeamMatchTitle;

  String get doublesProgressAllCompletedLabel =>
      doublesMatchStatusCompletedLabel;

  String get doublesNavigationMenuTooltip =>
      localeName.startsWith('ja') ? '操作メニューを開く' : 'Open operations menu';

  String get doublesNavigationShowHint =>
      localeName.startsWith('ja') ? '操作ヒントを表示' : 'Show operation hint';
}
