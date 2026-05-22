// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lanske';

  @override
  String get eventSetupTitle => 'Doubles Match Table ver0.1';

  @override
  String get matchTableList => 'Match table list';

  @override
  String get eventSetupInstruction =>
      'Paste a URL or enter the court and player counts manually.';

  @override
  String get eventSetupSupportedConditions =>
      'ver0.1 supports 1 court with 4 to 7 players and 2 courts with 8 to 15 players.';

  @override
  String get courtCountLabel => 'Courts';

  @override
  String get playerCountLabel => 'Players';

  @override
  String get decrementCourtCountTooltip => 'Decrease court count';

  @override
  String get incrementCourtCountTooltip => 'Increase court count';

  @override
  String get decrementPlayerCountTooltip => 'Decrease player count';

  @override
  String get incrementPlayerCountTooltip => 'Increase player count';

  @override
  String playerCountRangeHelp(int minPlayerCount, int maxPlayerCount) {
    return 'Enter between $minPlayerCount and $maxPlayerCount players.';
  }

  @override
  String get loadingEventInfo => 'Loading event info...';

  @override
  String get enterUrlMessage => 'Enter a URL.';

  @override
  String get enterTennisbearEventUrlMessage => 'Enter a TennisBear event URL.';

  @override
  String get eventInfoLoadedMessage => 'Event info loaded.';

  @override
  String get eventInfoPartiallyLoadedMessage =>
      'Event info loaded. Some details could not be imported.';

  @override
  String get eventInfoLoadFailedMessage =>
      'Could not load event info. Check the URL and try again.';

  @override
  String get clipboardUrlNotFoundMessage => 'No URL found in the clipboard.';

  @override
  String get pasteTennisbearEventUrlMessage => 'Paste a TennisBear event URL.';

  @override
  String get tennisbearEventUrlLabel => 'TennisBear event URL';

  @override
  String get tennisbearEventUrlHelper => 'Example: TennisBear event detail URL';

  @override
  String get tennisbearEventUrlError => 'Enter a TennisBear event URL.';

  @override
  String get clearUrlTooltip => 'Clear URL';

  @override
  String get pasteButton => 'Paste';

  @override
  String get importButton => 'Import';

  @override
  String get eventNameLabel => 'Event name';

  @override
  String get playerDisplayNameSectionTitle => 'Player display names';

  @override
  String get resetInputsButton => 'Reset inputs';

  @override
  String get generateScheduleButton => 'Generate match table';
}
