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
  String get eventSetupTitle => 'Lanske: Doubles Scheduler';

  @override
  String get topPageMenu => 'Top';

  @override
  String get matchTableList => 'Match table list';

  @override
  String get supportMenuTitle => 'Support page (Japanese)';

  @override
  String get supportMenuSubtitle => 'Feedback form is linked there';

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
      'The match table had been updated, so the latest version is now displayed.';

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

  @override
  String courtDisplaySummary(String courtLabels) {
    return 'Court display: $courtLabels';
  }

  @override
  String get changeCourtDisplayButton => 'Change';

  @override
  String get displaySettingsDialogTitle => 'Display settings';

  @override
  String get courtDisplaySectionTitle => 'Court display';

  @override
  String get courtDisplayPresetNumbers => '1 / 2';

  @override
  String get courtDisplayPresetLetters => 'A / B';

  @override
  String get courtDisplayPresetLeftRight => 'Left / Right';

  @override
  String get courtDisplayPresetFrontBack => 'Front / Back';

  @override
  String get courtDisplayPresetCustom => 'Custom';

  @override
  String courtDisplayInputLabel(int courtNumber) {
    return 'Court $courtNumber';
  }

  @override
  String get courtDisplayEmptyError => 'Enter a court display label.';

  @override
  String get courtDisplayDuplicateError =>
      'Court display labels must be unique.';

  @override
  String get confirmButton => 'OK';

  @override
  String get courtDisplayLabelLeft => 'L';

  @override
  String get courtDisplayLabelRight => 'R';

  @override
  String get courtDisplayLabelFront => 'F';

  @override
  String get courtDisplayLabelBack => 'B';

  @override
  String get shareUrlButton => 'Share URL';

  @override
  String get closeButton => 'Close';

  @override
  String get scheduleHistoryEmptyMessage => 'No match table view history';

  @override
  String get clearScheduleHistoryTooltip => 'Delete match table view history';

  @override
  String get clearScheduleHistoryConfirmTitle =>
      'Delete match table view history?';

  @override
  String get clearScheduleHistoryConfirmBody =>
      'This deletes the match table view history on this device. Deleted history will return to the list when opened again from a shared URL or QR code.';

  @override
  String get clearScheduleHistoryActionButton => 'Delete history';

  @override
  String get scheduleHistoryClearedMessage =>
      'Match table view history deleted';

  @override
  String get saveButton => 'Save';

  @override
  String get teamSetupMenuTitle => 'Lanske: Team';

  @override
  String get teamSetupMenuSubtitle => 'Create a team match table';

  @override
  String get teamSetupTitle => 'Lanske: Team';

  @override
  String get teamSetupInstruction =>
      'Set simultaneous matches, participants, and preferred team size to create a team match table.';

  @override
  String get teamSetupSupportedConditions =>
      'For the initial alpha, the backend API creates a 5-round team match table.';

  @override
  String get teamSetupInputUpperLimitNote =>
      'Input limits: 5 simultaneous matches / 50 participants / preferred team size 25 / 25 teams per match. Simultaneous matches are clamped to a safe range when needed.';

  @override
  String get concurrentMatchCountLabel => 'Simultaneous matches';

  @override
  String get participantCountLabel => 'Participants';

  @override
  String get preferredTeamSizeLabel => 'Preferred team size';

  @override
  String get teamsPerMatchLabel => 'Teams per match';

  @override
  String get decrementConcurrentMatchCountTooltip =>
      'Decrease simultaneous match count';

  @override
  String get incrementConcurrentMatchCountTooltip =>
      'Increase simultaneous match count';

  @override
  String get decrementParticipantCountTooltip => 'Decrease participant count';

  @override
  String get incrementParticipantCountTooltip => 'Increase participant count';

  @override
  String get decrementPreferredTeamSizeTooltip =>
      'Decrease preferred team size';

  @override
  String get incrementPreferredTeamSizeTooltip =>
      'Increase preferred team size';

  @override
  String get decrementTeamsPerMatchTooltip => 'Decrease teams per match';

  @override
  String get incrementTeamsPerMatchTooltip => 'Increase teams per match';

  @override
  String teamSetupRangeHelp(int minValue, int maxValue) {
    return 'Select a value from $minValue to $maxValue.';
  }

  @override
  String teamCountSummary(int teamCount) {
    return '$teamCount teams';
  }

  @override
  String get teamCountSummaryHelp =>
      'Calculated automatically from participants and preferred team size.';

  @override
  String teamDistributionSummary(String summary) {
    return 'Distribution: $summary';
  }

  @override
  String teamDistributionItem(int memberCount, int teamCount) {
    return '$teamCount teams of $memberCount';
  }

  @override
  String get teamDistributionSummaryHelp =>
      'If there is a remainder, some teams will have one fewer member.';

  @override
  String get teamParticipantInputTitle => 'Participant names';

  @override
  String get teamParticipantInputButton => 'Participant names';

  @override
  String get teamParticipantInputDescription =>
      'Paste participant names separated by new lines. Commas and tabs are also supported in a simple form.';

  @override
  String get teamParticipantInputLabel => 'Participant names';

  @override
  String get teamParticipantInputHint => 'Example:\nAlex\nBlair\nCasey';

  @override
  String get applyParticipantNamesButton => 'Apply participant names';

  @override
  String participantNameCountStatus(int nameCount, int participantCount) {
    return 'Names: $nameCount / Participants: $participantCount';
  }

  @override
  String participantNamesAppliedMessage(int nameCount) {
    return 'Applied $nameCount participant names.';
  }

  @override
  String participantNamesTrimmedMessage(int maxCount) {
    return 'Applied up to $maxCount participant names. Extra names were omitted.';
  }

  @override
  String get participantNamesTooFewMessage =>
      'Enter at least two participant names.';

  @override
  String get participantNamesEmptyMessage => 'Enter participant names.';

  @override
  String get resetTeamSetupButton => 'Reset inputs';

  @override
  String get generateTeamScheduleButton => 'Create team match table';

  @override
  String get teamSetupAlphaNoticeTitle => 'Alpha flow';

  @override
  String get teamSetupAlphaNoticeBody =>
      'After creation, the backend API result is saved and can be reopened from a share URL. Team changes and score input are not implemented yet.';

  @override
  String get teamSetupCreatedMessage => 'Team setup conditions were created.';

  @override
  String get teamScheduleTitle => 'Team match table';

  @override
  String get teamScheduleListTitle => 'Team match tables';

  @override
  String get teamScheduleListEmptyTitle => 'No team match tables yet';

  @override
  String get teamScheduleListEmptyMessage =>
      'Create a team match table or open one from a share URL to show it in this device list.';

  @override
  String get teamScheduleListLoadErrorTitle => 'Failed to load the list';

  @override
  String get teamScheduleListLoadErrorMessage =>
      'Could not read the saved history on this device. Please try again.';

  @override
  String get teamScheduleUntitledEvent => 'Untitled team match table';

  @override
  String teamScheduleListShareId(String shareId) {
    return 'Share ID: $shareId';
  }

  @override
  String teamScheduleListTeamCount(int teamCount) {
    return '$teamCount teams';
  }

  @override
  String teamScheduleListMemberCount(int memberCount) {
    return '$memberCount members';
  }

  @override
  String teamScheduleListUpdatedAt(String updatedAt) {
    return 'Updated: $updatedAt';
  }

  @override
  String get teamNavigationMenuTooltip => 'Open team menu';

  @override
  String get teamNavigationTitle => 'Team scheduler';

  @override
  String get teamNavigationSubtitle => 'Team menu';

  @override
  String get teamNavigationHome => 'Team setup';

  @override
  String get teamNavigationScheduleList => 'Match table list';

  @override
  String get teamNavigationSupport => 'Support';

  @override
  String get teamNavigationServiceList => 'Services';

  @override
  String get teamNavigationDoublesScheduler => 'Doubles scheduler';

  @override
  String get defaultTeamScheduleEventTitle => 'Team practice';

  @override
  String get teamScheduleBulkEditTitle => 'Edit details';

  @override
  String get teamScheduleBulkEditButton => 'Edit details';

  @override
  String get teamScheduleEventTitleLabel => 'Event title';

  @override
  String get teamScheduleMemoLabel => 'Memo';

  @override
  String get teamScheduleHasMemoTooltip => 'Has memo';

  @override
  String get teamScheduleBulkEditTeamsSection => 'Team names';

  @override
  String get teamScheduleBulkEditMembersSection => 'Member names';

  @override
  String teamScheduleTeamNameLabel(int teamSlot) {
    return 'Team $teamSlot';
  }

  @override
  String defaultTeamMemberName(int memberNo) {
    return 'Participant $memberNo';
  }

  @override
  String defaultTeamName(int teamNo) {
    return 'Team $teamNo';
  }

  @override
  String teamScheduleSummary(
      int teamCount, int memberCount, int concurrentMatchCount) {
    return '$teamCount teams / $memberCount members / $concurrentMatchCount simultaneous matches';
  }

  @override
  String get teamScheduleBackendDataNotice =>
      'Showing the saved backend API result. Display names can be edited on this screen.';

  @override
  String get creatingTeamScheduleMessage =>
      'Creating and saving team match table...';

  @override
  String get restoringTeamScheduleMessage =>
      'Loading saved team match table...';

  @override
  String get savingTeamScheduleDisplayMessage => 'Saving display names...';

  @override
  String get teamScheduleGenerateFailedTitle =>
      'Failed to create team match table';

  @override
  String get teamScheduleGenerateFailedBody =>
      'Check the backend API or Firestore save response.';

  @override
  String teamScheduleGenerateFailedBodyWithDetail(String detail) {
    return 'Check the backend API or Firestore save response.\n\n$detail';
  }

  @override
  String get teamScheduleRestoreFailedTitle =>
      'Failed to load team match table';

  @override
  String get teamScheduleRestoreFailedBody =>
      'Check the share ID or saved data.';

  @override
  String teamScheduleRestoreFailedBodyWithDetail(String detail) {
    return 'Check the share ID or saved data.\n\n$detail';
  }

  @override
  String teamScheduleDisplaySaveFailedMessage(String detail) {
    return 'Failed to save display names: $detail';
  }

  @override
  String get retryTeamScheduleGenerateButton => 'Try again';

  @override
  String get retryTeamScheduleRestoreButton => 'Reload';

  @override
  String get teamScheduleShareTitle => 'Share URL';

  @override
  String get teamScheduleShareDescription =>
      'Share this URL to reopen the saved team match table.';

  @override
  String teamScheduleShareIdLabel(String shareId) {
    return 'Share ID: $shareId';
  }

  @override
  String get copyTeamScheduleShareUrlButton => 'Copy share URL';

  @override
  String get teamScheduleShareUrlCopiedMessage => 'Copied share URL.';

  @override
  String get nextTeamMatchTitle => 'Next match';

  @override
  String teamRoundTitle(int roundNo) {
    return 'Round $roundNo';
  }

  @override
  String teamCourtTitle(int courtNo) {
    return 'Court $courtNo';
  }

  @override
  String teamCourtMatchTitle(int courtNo, String matchTitle) {
    return 'Court $courtNo: $matchTitle';
  }

  @override
  String get teamListTitle => 'Teams';

  @override
  String teamChoiceLabel(String teamName, int memberCount) {
    return '$teamName ($memberCount members)';
  }

  @override
  String selectedTeamMembersTitle(String teamName) {
    return '$teamName members';
  }

  @override
  String get teamMatchVsSeparator => ' vs ';

  @override
  String get teamMatchGroupSeparator => ' / ';

  @override
  String get teamMatchVsLabel => 'vs';

  @override
  String get editTeamScheduleEventTitleTooltip => 'Edit event title';

  @override
  String get editTeamNameTooltip => 'Edit team name';

  @override
  String get editTeamMemberNameTooltip => 'Edit member display name';

  @override
  String get editTeamScheduleEventTitleDialogTitle => 'Edit event title';

  @override
  String editTeamNameDialogTitle(String teamName) {
    return 'Edit $teamName';
  }

  @override
  String editTeamMemberNameDialogTitle(String memberName) {
    return 'Edit $memberName';
  }

  @override
  String get displayNameInputLabel => 'Display name';

  @override
  String get teamScheduleSportSectionTitle => 'Score input';

  @override
  String get teamScheduleSportNoneLabel => 'Not selected';

  @override
  String get teamScheduleSportBocciaLabel => 'Boccia';

  @override
  String get teamScheduleSportHelp =>
      'Select a sport to enter scores from match cards.';

  @override
  String get savingTeamScheduleScoresMessage => 'Saving scores...';

  @override
  String teamScheduleScoresSaveFailedMessage(String detail) {
    return 'Failed to save scores: $detail';
  }

  @override
  String get teamScheduleConcurrentEditNotice =>
      'When editing from multiple devices at the same time, saved data may not be reflected as intended.';

  @override
  String get refreshingTeamScheduleScoresMessage =>
      'Refreshing latest score data...';

  @override
  String get bocciaScoreRefreshedMessage => 'Refreshed latest data';

  @override
  String get refreshBocciaScoreFailedMessage => 'Failed to refresh latest data';

  @override
  String get refreshBocciaScoreDiscardChangesTitle =>
      'Discard unsaved changes and refresh?';

  @override
  String get refreshBocciaScoreDiscardChangesBody =>
      'Refreshing latest data will discard unsaved changes.';

  @override
  String get confirmRefreshBocciaScoreButton => 'Refresh';

  @override
  String get selectSportBeforeScoreInputMessage => 'Select a sport first.';

  @override
  String get unsupportedBocciaMatchMessage =>
      'Boccia score input supports two-team matches only.';

  @override
  String get inputBocciaScoreButton => 'Enter score';

  @override
  String get editBocciaScoreButton => 'Edit score';

  @override
  String bocciaScoreSummary(
      String redTeamName, int redScore, int blueScore, String blueTeamName) {
    return '$redTeamName $redScore - $blueScore $blueTeamName';
  }

  @override
  String get bocciaScoreDialogTitle => 'Boccia score input';

  @override
  String bocciaScoreDialogMatchTitle(String redTeamName, String blueTeamName) {
    return '$redTeamName vs $blueTeamName';
  }

  @override
  String bocciaThrowLogTitle(int endNo) {
    return 'End $endNo throw log';
  }

  @override
  String get bocciaThrowLogHelp =>
      'Tap + for a participant assigned to a throwing box to add a throw log for this end.';

  @override
  String bocciaThrowCountSummary(int redCount, int blueCount) {
    return 'Throws: Red $redCount / Blue $blueCount';
  }

  @override
  String bocciaThrowCountProgress(int count, int maxCount) {
    return '$count / $maxCount throws';
  }

  @override
  String get bocciaFirstTeamLabel => 'First';

  @override
  String get bocciaSecondTeamLabel => 'Second';

  @override
  String get bocciaRedSideLabel => 'Red';

  @override
  String get bocciaBlueSideLabel => 'Blue';

  @override
  String get swapBocciaOrderButton => 'Swap order';

  @override
  String get swapBocciaOrderTooltip => 'Swap teams and their scores';

  @override
  String bocciaEndLabel(int endNo) {
    return 'E$endNo';
  }

  @override
  String get bocciaThrowingBoxSettingsButton => 'Set throwing boxes';

  @override
  String get bocciaReturnToThrowLogButton => 'Back to throw log';

  @override
  String get bocciaThrowingBoxLockedMessage =>
      'Throwing boxes cannot be changed after throw logs are entered.';

  @override
  String get bocciaUnusedThrowingBoxLabel => 'Unused';

  @override
  String bocciaDefaultParticipantName(int playerSlot) {
    return 'Participant $playerSlot';
  }

  @override
  String bocciaThrowCountForBox(int count) {
    return 'Throws: $count';
  }

  @override
  String get bocciaAddThrowLogTooltip => 'Add throw log';

  @override
  String get bocciaThrowOrderTitle => 'Throw order';

  @override
  String get bocciaNoThrowLogsMessage => 'No throw logs yet.';

  @override
  String get clearBocciaEndThrowLogsButton => 'Clear this end';

  @override
  String bocciaThrowOrderItem(
      int throwNo, String playerName, String sideLabel, int boxNo) {
    return '$throwNo. $playerName ($sideLabel / Box $boxNo)';
  }

  @override
  String get removeLastBocciaThrowLogTooltip => 'Undo last throw';

  @override
  String get bocciaTotalLabel => 'Total';

  @override
  String get bocciaScoreSavedMessage => 'Saved.';

  @override
  String get bocciaScoreUnsavedChangesMessage => 'There are unsaved changes.';

  @override
  String get bocciaScoreDiscardChangesTitle => 'Unsaved changes';

  @override
  String get bocciaScoreDiscardChangesBody =>
      'There are unsaved score changes. Do you want to close?';

  @override
  String get clearBocciaEndThrowLogsDialogTitle =>
      'Clear throw logs for this end?';

  @override
  String get clearBocciaEndThrowLogsDialogBody =>
      'This will delete the throw order and throw counts for the selected end. This action cannot be undone.';

  @override
  String get confirmClearBocciaEndThrowLogsButton => 'Clear';

  @override
  String get returnToBocciaScoreInputButton => 'Back to input';

  @override
  String get discardBocciaScoreChangesButton => 'Close without saving';

  @override
  String get saveAndCloseBocciaScoreButton => 'Save and close';

  @override
  String get doublesMatchEditTitle => 'Match status and final score';

  @override
  String get doublesMatchStatusScheduledLabel => 'Scheduled';

  @override
  String get doublesMatchStatusInProgressLabel => 'In progress';

  @override
  String get doublesMatchStatusCompletedLabel => 'Completed';

  @override
  String get doublesMatchScorePickerTitle => 'Select score';

  @override
  String get doublesMatchScoreUnsetLabel => 'Clear score';

  @override
  String get doublesMatchStartTimeLabel => 'Start time';

  @override
  String get doublesMatchEndTimeLabel => 'End time';

  @override
  String get doublesMatchSetCurrentTimeTooltip => 'Set current time';

  @override
  String get doublesMatchNoteLabel => 'Match note';

  @override
  String get doublesMatchSaveButton => 'Save';

  @override
  String get doublesMatchWinnerLabel => 'Winner';

  @override
  String get doublesMatchLoserLabel => 'Loser';

  @override
  String get doublesMatchDrawLabel => 'Draw';

  @override
  String get doublesMatchSavedMessage => 'Match information saved';

  @override
  String get doublesMatchRefreshedMessage => 'Match information refreshed';

  @override
  String get doublesMatchConflictMessage =>
      'This match was updated on another device. Refresh the latest information.';

  @override
  String get doublesMatchIncompleteScoreMessage =>
      'Enter both scores or leave both scores unset.';

  @override
  String get doublesMatchTimeOrderErrorMessage =>
      'End time must not be earlier than start time.';

  @override
  String get doublesMatchUnavailableMessage =>
      'Schedule information required to edit this match is unavailable.';

  @override
  String get doublesMatchScheduleChangedMessage =>
      'The schedule was updated on another device. Reload the latest schedule.';

  @override
  String doublesMatchSaveFailedMessage(String error) {
    return 'Could not save match information: $error';
  }

  @override
  String appFooterText(String version) {
    return '© 2026 S.R.P. · ver.$version';
  }

  @override
  String get editDoublesEventInfoButton => 'Edit event information';

  @override
  String get editDoublesEventInfoDialogTitle => 'Edit event information';

  @override
  String get doublesEventTitleLabel => 'Event title';

  @override
  String get doublesEventMemoLabel => 'Memo';

  @override
  String get doublesEventTitleRequiredMessage => 'Enter an event title.';

  @override
  String get doublesPlayerDisplayNameRequiredMessage =>
      'Enter a player display name.';

  @override
  String get doublesEventInfoSavedMessage => 'Event information saved.';

  @override
  String get doublesEventInfoConflictMessage =>
      'Event information was updated on another device. Your input has been kept. Review the latest information and save again.';

  @override
  String get doublesEventInfoLatestLoadFailedMessage =>
      'Could not load the latest event information. Refresh the page and try again.';

  @override
  String doublesEventInfoSaveFailedMessage(String error) {
    return 'Could not save event information: $error';
  }
}
