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
  String get topPageMenu => 'Top';

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
  String playerDisplayNameInputLabel(int playerNumber, String sourceName) {
    return 'Player $playerNumber: $sourceName';
  }

  @override
  String get resetInputsButton => 'Reset inputs';

  @override
  String get generateScheduleButton => 'Generate match table';

  @override
  String get generateButton => 'Generate';

  @override
  String get regenerateButton => 'Regenerate';

  @override
  String get adoptingScheduleButton => 'Adopting';

  @override
  String get adoptScheduleButton => 'Use this table';

  @override
  String get cannotRegenerateAdoptedScheduleMessage =>
      'This table has already been adopted and cannot be regenerated.';

  @override
  String get regenerateConfirmTitle => 'Regenerate?';

  @override
  String get regenerateConfirmBody =>
      'The currently displayed match table will be replaced.\nUnadopted tables shown from the share URL will also be updated.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get regenerateActionButton => 'Regenerate';

  @override
  String get scheduleNotFoundMessage => 'Match table not found.';

  @override
  String get shareUrlCreateFailedMessage => 'Could not create the URL.';

  @override
  String get shareUrlCopiedMessage => 'URL copied.';

  @override
  String generateScheduleFailedMessage(String error) {
    return 'Could not generate the match table: $error';
  }

  @override
  String get reloadScheduleMissingIdMessage =>
      'No generated_schedule_id is available for reload.';

  @override
  String reloadScheduleFailedMessage(String error) {
    return 'Could not load the match table: $error';
  }

  @override
  String get adoptScheduleMissingIdMessage =>
      'No generated_schedule_id is available for adoption.';

  @override
  String get adoptEventMissingMessage =>
      'No event information is available for adoption.';

  @override
  String get alreadyAdoptedScheduleMessage =>
      'This table has already been adopted.';

  @override
  String get scheduleUpdatedReloadMessage =>
      'The match table has been updated. Loading the latest information.';

  @override
  String get adoptScheduleCompletedMessage => 'This match table was adopted.';

  @override
  String adoptScheduleFailedMessage(String error) {
    return 'Could not adopt the match table: $error';
  }

  @override
  String schedulePlayersTitle(int courtCount, int playerCount) {
    return 'Courts: $courtCount    Players: $playerCount';
  }

  @override
  String get matchTableTitle => 'Match table';

  @override
  String get errorTitle => 'Error';

  @override
  String get copyUrlButton => 'Copy URL';

  @override
  String get refreshLatestButton => 'Refresh';

  @override
  String get shareUrlDescription =>
      'Share the URL so everyone can check the match table.';

  @override
  String get playersTitle => 'Players';

  @override
  String get noPlayersMessage => 'No player information is available.';

  @override
  String get scheduleNotLoadedMessage => 'The match table has not been loaded.';

  @override
  String get scheduleDataEmptyMessage => 'No match table data is available.';

  @override
  String get restLabel => 'Rest';

  @override
  String restCountLabel(int restCount) {
    return '$restCount rest';
  }

  @override
  String lastOpenedAtLabel(String lastOpenedAt) {
    return 'Last opened: $lastOpenedAt';
  }

  @override
  String get removePlayerTooltip => 'Remove this player';

  @override
  String get cannotRemovePlayerTooltip =>
      'Cannot remove because the minimum player count has been reached.';
}
