import 'app_localizations.dart';

extension TeamL10n on AppLocalizations {
  bool get _isJapanese => localeName.startsWith('ja');

  String get teamSetupMenuTitle => _isJapanese ? 'らんすけ：チーム' : 'Lanske: Team';

  String get teamSetupMenuSubtitle =>
      _isJapanese ? 'チーム用対戦表を作成' : 'Create a team match table';

  String get teamSetupTitle => _isJapanese ? 'らんすけ：チーム' : 'Lanske: Team';

  String get teamSetupInstruction => _isJapanese
      ? '同時進行試合数・参加人数・1チームの目安人数を決めて、チーム用対戦表を作成します。'
      : 'Set simultaneous matches, participants, and preferred team size to create a team match table.';

  String get teamSetupSupportedConditions => _isJapanese
      ? '初期alphaでは、backend APIで5ラウンド分のチーム対戦表を作成します。'
      : 'For the initial alpha, the backend API creates a 5-round team match table.';

  String get teamSetupInputUpperLimitNote => _isJapanese
      ? '入力上限: 同時進行試合数5 / 参加人数50 / 1チームの目安人数25 / 1試合で対戦するチーム数25。条件により同時進行数は安全範囲に丸めます。'
      : 'Input limits: 5 simultaneous matches / 50 participants / preferred team size 25 / 25 teams per match. Simultaneous matches are clamped to a safe range when needed.';

  String get concurrentMatchCountLabel =>
      _isJapanese ? '同時進行試合数' : 'Simultaneous matches';

  String get participantCountLabel => _isJapanese ? '参加人数' : 'Participants';

  String get preferredTeamSizeLabel =>
      _isJapanese ? '1チームの目安人数' : 'Preferred team size';

  String get teamsPerMatchLabel =>
      _isJapanese ? '1試合で対戦するチーム数' : 'Teams per match';

  String get decrementConcurrentMatchCountTooltip =>
      _isJapanese ? '同時進行試合数を減らす' : 'Decrease simultaneous match count';

  String get incrementConcurrentMatchCountTooltip =>
      _isJapanese ? '同時進行試合数を増やす' : 'Increase simultaneous match count';

  String get decrementParticipantCountTooltip =>
      _isJapanese ? '参加人数を減らす' : 'Decrease participant count';

  String get incrementParticipantCountTooltip =>
      _isJapanese ? '参加人数を増やす' : 'Increase participant count';

  String get decrementPreferredTeamSizeTooltip =>
      _isJapanese ? '1チームの目安人数を減らす' : 'Decrease preferred team size';

  String get incrementPreferredTeamSizeTooltip =>
      _isJapanese ? '1チームの目安人数を増やす' : 'Increase preferred team size';

  String get decrementTeamsPerMatchTooltip =>
      _isJapanese ? '1試合で対戦するチーム数を減らす' : 'Decrease teams per match';

  String get incrementTeamsPerMatchTooltip =>
      _isJapanese ? '1試合で対戦するチーム数を増やす' : 'Increase teams per match';

  String teamSetupRangeHelp(int minValue, int maxValue) {
    return _isJapanese
        ? '$minValue〜$maxValue の範囲で選択できます。'
        : 'Select a value from $minValue to $maxValue.';
  }

  String teamCountSummary(int teamCount) {
    return _isJapanese ? '$teamCountチーム' : '$teamCount teams';
  }

  String get teamCountSummaryHelp => _isJapanese
      ? '参加人数と1チームの目安人数から自動計算します。'
      : 'Calculated automatically from participants and preferred team size.';

  String teamDistributionSummary(String summary) {
    return _isJapanese ? '内訳: $summary' : 'Distribution: $summary';
  }

  String get teamDistributionSummaryHelp => _isJapanese
      ? '余りがある場合は、一部チームの人数が1人少なくなります。'
      : 'If there is a remainder, some teams will have one fewer member.';

  String get teamParticipantInputTitle =>
      _isJapanese ? '参加者名の取り込み' : 'Participant names';

  String get teamParticipantInputDescription => _isJapanese
      ? '改行区切りで参加者名を貼り付けて反映できます。カンマ・読点・タブ区切りも簡易対応します。'
      : 'Paste participant names separated by new lines. Commas and tabs are also supported in a simple form.';

  String get teamParticipantInputLabel =>
      _isJapanese ? '参加者名' : 'Participant names';

  String get teamParticipantInputHint =>
      _isJapanese ? '例:\n田中\n佐藤\n鈴木' : 'Example:\nAlex\nBlair\nCasey';

  String get applyParticipantNamesButton =>
      _isJapanese ? '参加者名を反映' : 'Apply participant names';

  String participantNameCountStatus(int nameCount, int participantCount) {
    return _isJapanese
        ? '入力済み: $nameCount人 / 参加人数: $participantCount人'
        : 'Names: $nameCount / Participants: $participantCount';
  }

  String participantNamesAppliedMessage(int nameCount) {
    return _isJapanese
        ? '$nameCount人の参加者名を反映しました'
        : 'Applied $nameCount participant names.';
  }

  String participantNamesTrimmedMessage(int maxCount) {
    return _isJapanese
        ? '$maxCount人まで取り込みました。超過分は省略しました。'
        : 'Applied up to $maxCount participant names. Extra names were omitted.';
  }

  String get participantNamesTooFewMessage => _isJapanese
      ? '参加者名は2人以上入力してください。'
      : 'Enter at least two participant names.';

  String get participantNamesEmptyMessage =>
      _isJapanese ? '参加者名を入力してください。' : 'Enter participant names.';

  String get resetTeamSetupButton => _isJapanese ? '入力項目のリセット' : 'Reset inputs';

  String get generateTeamScheduleButton =>
      _isJapanese ? 'チーム対戦表を作成' : 'Create team match table';

  String get teamSetupAlphaNoticeTitle =>
      _isJapanese ? 'alpha確認中' : 'Alpha flow';

  String get teamSetupAlphaNoticeBody => _isJapanese
      ? '作成後、backend API の生成結果を保存し、共有URLから再表示できます。チーム変更・スコア入力はまだ未実装です。'
      : 'After creation, the backend API result is saved and can be reopened from a share URL. Team changes and score input are not implemented yet.';

  String get teamSetupMockNoticeTitle => teamSetupAlphaNoticeTitle;

  String get teamSetupMockNoticeBody => teamSetupAlphaNoticeBody;

  String get teamSetupCreatedMessage => _isJapanese
      ? 'チーム用セットアップ条件を作成しました'
      : 'Team setup conditions were created.';

  String get teamScheduleTitle => _isJapanese ? 'チーム対戦表' : 'Team match table';

  String get teamScheduleListTitle =>
      _isJapanese ? 'チーム対戦表一覧' : 'Team match tables';

  String get teamScheduleListEmptyTitle =>
      _isJapanese ? 'チーム対戦表はまだありません' : 'No team match tables yet';

  String get teamScheduleListEmptyMessage => _isJapanese
      ? 'チーム対戦表を作成または共有URLから開くと、この端末の一覧に表示されます。'
      : 'Create a team match table or open one from a share URL to show it in this device list.';

  String get teamScheduleListLoadErrorTitle =>
      _isJapanese ? '一覧を読み込めませんでした' : 'Failed to load the list';

  String get teamScheduleListLoadErrorMessage => _isJapanese
      ? '端末内の保存履歴を確認できませんでした。もう一度お試しください。'
      : 'Could not read the saved history on this device. Please try again.';

  String get teamScheduleUntitledEvent =>
      _isJapanese ? 'タイトル未設定のチーム対戦表' : 'Untitled team match table';

  String teamScheduleListShareId(String shareId) {
    return _isJapanese ? '共有ID: $shareId' : 'Share ID: $shareId';
  }

  String teamScheduleListTeamCount(int teamCount) {
    return _isJapanese ? '$teamCountチーム' : '$teamCount teams';
  }

  String teamScheduleListMemberCount(int memberCount) {
    return _isJapanese ? '$memberCount人' : '$memberCount members';
  }

  String teamScheduleListUpdatedAt(String updatedAt) {
    return _isJapanese ? '更新: $updatedAt' : 'Updated: $updatedAt';
  }

  String get refreshLatestInfo => refreshLatestTeamScheduleButton;

  String get teamNavigationMenuTooltip =>
      _isJapanese ? 'チーム用メニューを開く' : 'Open team menu';

  String get teamNavigationTitle => _isJapanese ? 'チーム乱数表' : 'Team scheduler';

  String get teamNavigationSubtitle => _isJapanese ? 'チーム用メニュー' : 'Team menu';

  String get teamNavigationHome => _isJapanese ? 'チームTOP' : 'Team setup';

  String get teamNavigationScheduleList =>
      _isJapanese ? '対戦表一覧' : 'Match table list';

  String get teamNavigationSupport => _isJapanese ? 'サポート' : 'Support';

  String get teamNavigationServiceList => _isJapanese ? 'サービス一覧' : 'Services';

  String get teamNavigationDoublesScheduler =>
      _isJapanese ? 'ダブルス乱数表' : 'Doubles scheduler';

  String get defaultTeamScheduleEventTitle =>
      _isJapanese ? 'チーム練習会' : 'Team practice';

  String get teamScheduleBulkEditTitle =>
      _isJapanese ? 'まとめて編集' : 'Edit details';

  String get teamScheduleBulkEditButton =>
      _isJapanese ? 'まとめて編集' : 'Edit details';

  String get teamScheduleEventTitleLabel =>
      _isJapanese ? 'イベントタイトル' : 'Event title';

  String get teamScheduleMemoLabel => _isJapanese ? 'メモ' : 'Memo';

  String get teamScheduleHasMemoTooltip => _isJapanese ? 'メモあり' : 'Has memo';

  String get teamScheduleBulkEditTeamsSection =>
      _isJapanese ? 'チーム名' : 'Team names';

  String get teamScheduleBulkEditMembersSection =>
      _isJapanese ? 'メンバー名' : 'Member names';

  String teamScheduleTeamNameLabel(int teamSlot) =>
      _isJapanese ? 'チーム$teamSlot' : 'Team $teamSlot';

  String get cancel => _isJapanese ? 'キャンセル' : 'Cancel';

  String get save => _isJapanese ? '保存' : 'Save';

  String defaultTeamMemberName(int memberNo) {
    return _isJapanese ? '参加者$memberNo' : 'Participant $memberNo';
  }

  String defaultTeamName(int teamNo) {
    return _isJapanese ? 'チーム$teamNo' : 'Team $teamNo';
  }

  String teamScheduleSummary({
    required int teamCount,
    required int memberCount,
    required int concurrentMatchCount,
  }) {
    return _isJapanese
        ? '$teamCountチーム / $memberCount人 / $concurrentMatchCount同時進行'
        : '$teamCount teams / $memberCount members / $concurrentMatchCount simultaneous matches';
  }

  String get teamScheduleMockDataNotice => teamScheduleBackendDataNotice;

  String get teamScheduleBackendDataNotice => _isJapanese
      ? 'backend API の生成結果を保存して表示しています。表示名はこの画面内で編集できます。'
      : 'Showing the saved backend API result. Display names can be edited on this screen.';

  String get creatingTeamScheduleMessage => _isJapanese
      ? 'チーム対戦表を作成・保存中です…'
      : 'Creating and saving team match table...';

  String get restoringTeamScheduleMessage => _isJapanese
      ? '保存済みのチーム対戦表を読み込み中です…'
      : 'Loading saved team match table...';

  String get savingTeamScheduleDisplayMessage =>
      _isJapanese ? '表示名を保存中です…' : 'Saving display names...';

  String get teamScheduleGenerateFailedTitle =>
      _isJapanese ? 'チーム対戦表の作成に失敗しました' : 'Failed to create team match table';

  String teamScheduleGenerateFailedBody(String detail) {
    if (detail.isEmpty) {
      return _isJapanese
          ? 'backend API または Firestore 保存の応答を確認してください。'
          : 'Check the backend API or Firestore save response.';
    }

    return _isJapanese
        ? 'backend API または Firestore 保存の応答を確認してください。\n\n$detail'
        : 'Check the backend API or Firestore save response.\n\n$detail';
  }

  String get teamScheduleRestoreFailedTitle =>
      _isJapanese ? 'チーム対戦表の読み込みに失敗しました' : 'Failed to load team match table';

  String teamScheduleRestoreFailedBody(String detail) {
    if (detail.isEmpty) {
      return _isJapanese
          ? '共有IDまたは保存済みデータを確認してください。'
          : 'Check the share ID or saved data.';
    }

    return _isJapanese
        ? '共有IDまたは保存済みデータを確認してください。\n\n$detail'
        : 'Check the share ID or saved data.\n\n$detail';
  }

  String teamScheduleDisplaySaveFailedMessage(String detail) {
    return _isJapanese
        ? '表示名の保存に失敗しました: $detail'
        : 'Failed to save display names: $detail';
  }

  String get retryTeamScheduleGenerateButton =>
      _isJapanese ? 'もう一度作成' : 'Try again';

  String get retryTeamScheduleRestoreButton =>
      _isJapanese ? 'もう一度読み込む' : 'Reload';

  String get teamScheduleShareTitle => _isJapanese ? '共有URL' : 'Share URL';

  String get teamScheduleShareDescription => _isJapanese
      ? 'このURLを共有すると、保存済みのチーム対戦表を開き直せます。'
      : 'Share this URL to reopen the saved team match table.';

  String teamScheduleShareIdLabel(String shareId) {
    return _isJapanese ? '共有ID: $shareId' : 'Share ID: $shareId';
  }

  String get copyTeamScheduleShareUrlButton =>
      _isJapanese ? '共有URLをコピー' : 'Copy share URL';

  String get teamScheduleShareUrlCopiedMessage =>
      _isJapanese ? '共有URLをコピーしました' : 'Copied share URL.';

  String get nextTeamMatchTitle => _isJapanese ? '次の対戦' : 'Next match';

  String teamRoundTitle(int roundNo) {
    return _isJapanese ? '第$roundNoラウンド' : 'Round $roundNo';
  }

  String teamCourtTitle(int courtNo) {
    return _isJapanese ? 'コート$courtNo' : 'Court $courtNo';
  }

  String teamCourtMatchTitle({
    required int courtNo,
    required String matchTitle,
  }) {
    return '${teamCourtTitle(courtNo)}: $matchTitle';
  }

  String get teamListTitle => _isJapanese ? 'チーム一覧' : 'Teams';

  String teamChoiceLabel({
    required String teamName,
    required int memberCount,
  }) {
    return _isJapanese
        ? '$teamName ($memberCount人)'
        : '$teamName ($memberCount members)';
  }

  String selectedTeamMembersTitle(String teamName) {
    return _isJapanese ? '$teamName のメンバー' : '$teamName members';
  }

  String get teamMatchVsSeparator => ' vs ';

  String get teamMatchGroupSeparator => ' / ';

  String get editTeamScheduleEventTitleTooltip =>
      _isJapanese ? 'イベントタイトルを編集' : 'Edit event title';

  String get editTeamNameTooltip => _isJapanese ? 'チーム名を編集' : 'Edit team name';

  String get editTeamMemberNameTooltip =>
      _isJapanese ? 'メンバー表示名を編集' : 'Edit member display name';

  String get editTeamScheduleEventTitleDialogTitle =>
      _isJapanese ? 'イベントタイトルを編集' : 'Edit event title';

  String editTeamNameDialogTitle(String teamName) {
    return _isJapanese ? '$teamName を編集' : 'Edit $teamName';
  }

  String editTeamMemberNameDialogTitle(String memberName) {
    return _isJapanese ? '$memberName を編集' : 'Edit $memberName';
  }

  String get displayNameInputLabel => _isJapanese ? '表示名' : 'Display name';

  String get cancelDisplayNameEditButton => _isJapanese ? 'キャンセル' : 'Cancel';

  String get saveDisplayNameEditButton => _isJapanese ? '保存' : 'Save';

  String get teamScheduleSportSectionTitle =>
      _isJapanese ? 'スコア入力' : 'Score input';

  String get teamScheduleSportNoneLabel => _isJapanese ? '未選択' : 'Not selected';

  String get teamScheduleSportBocciaLabel => _isJapanese ? 'ボッチャ' : 'Boccia';

  String get teamScheduleSportHelp => _isJapanese
      ? '競技を選択すると、対戦カードからスコアを入力できます。'
      : 'Select a sport to enter scores from match cards.';

  String get savingTeamScheduleScoresMessage =>
      _isJapanese ? 'スコアを保存中です…' : 'Saving scores...';

  String teamScheduleScoresSaveFailedMessage(String detail) {
    return _isJapanese
        ? 'スコアの保存に失敗しました: $detail'
        : 'Failed to save scores: $detail';
  }

  String get refreshLatestTeamScheduleButton =>
      _isJapanese ? '最新の情報に更新' : 'Refresh latest';

  String get teamScheduleConcurrentEditNotice => _isJapanese
      ? '複数端末で同時に編集すると、保存内容が意図どおり反映されない場合があります。'
      : 'When editing from multiple devices at the same time, saved data may not be reflected as intended.';

  String get refreshingTeamScheduleScoresMessage =>
      _isJapanese ? '最新のスコア情報を取得しています...' : 'Refreshing latest score data...';

  String get bocciaScoreRefreshedMessage =>
      _isJapanese ? '最新の情報に更新しました' : 'Refreshed latest data';

  String get refreshBocciaScoreFailedMessage =>
      _isJapanese ? '最新の情報を取得できませんでした' : 'Failed to refresh latest data';

  String get refreshBocciaScoreDiscardChangesTitle => _isJapanese
      ? '未保存の変更を破棄して更新しますか？'
      : 'Discard unsaved changes and refresh?';

  String get refreshBocciaScoreDiscardChangesBody => _isJapanese
      ? '最新の情報に更新すると、保存していない入力内容は破棄されます。'
      : 'Refreshing latest data will discard unsaved changes.';

  String get cancelRefreshBocciaScoreButton => _isJapanese ? 'キャンセル' : 'Cancel';

  String get confirmRefreshBocciaScoreButton =>
      _isJapanese ? '更新する' : 'Refresh';

  String get selectSportBeforeScoreInputMessage =>
      _isJapanese ? '先に競技を選択してください。' : 'Select a sport first.';

  String get unsupportedBocciaMatchMessage => _isJapanese
      ? 'ボッチャのスコア入力は2チーム対戦のみ対応しています。'
      : 'Boccia score input supports two-team matches only.';

  String get inputBocciaScoreButton => _isJapanese ? 'スコア入力' : 'Enter score';

  String get editBocciaScoreButton => _isJapanese ? 'スコア編集' : 'Edit score';

  String bocciaScoreSummary({
    required String redTeamName,
    required int redScore,
    required String blueTeamName,
    required int blueScore,
  }) {
    return '$redTeamName $redScore - $blueScore $blueTeamName';
  }

  String get bocciaScoreDialogTitle =>
      _isJapanese ? 'ボッチャ スコア入力' : 'Boccia score input';

  String bocciaScoreDialogMatchTitle({
    required String redTeamName,
    required String blueTeamName,
  }) {
    return '$redTeamName vs $blueTeamName';
  }

  String bocciaThrowLogTitle(int endNo) {
    return _isJapanese ? '${endNo}E 投球ログ' : 'End $endNo throw log';
  }

  String get bocciaThrowLogHelp => _isJapanese
      ? '投球場所に設定された参加者の＋を押すと、このエンドの投球ログに追加します。'
      : 'Tap + for a participant assigned to a throwing box to add a throw log for this end.';

  String bocciaThrowCountSummary({
    required int redCount,
    required int blueCount,
  }) {
    return _isJapanese
        ? '投球数：赤：$redCount　青：$blueCount'
        : 'Throws: Red $redCount / Blue $blueCount';
  }

  String bocciaThrowCountProgress({
    required int count,
    required int maxCount,
  }) {
    return _isJapanese ? '$count / $maxCount投' : '$count / $maxCount throws';
  }

  String get bocciaFirstTeamLabel => _isJapanese ? '先攻' : 'First';

  String get bocciaSecondTeamLabel => _isJapanese ? '後攻' : 'Second';

  String get bocciaRedSideLabel => _isJapanese ? '赤' : 'Red';

  String get bocciaBlueSideLabel => _isJapanese ? '青' : 'Blue';

  String get swapBocciaOrderButton => _isJapanese ? '先攻 🔁 後攻' : 'Swap order';

  String get swapBocciaOrderTooltip =>
      _isJapanese ? '先攻と後攻をスコアごと入れ替える' : 'Swap teams and their scores';

  String bocciaEndLabel(int endNo) {
    return _isJapanese ? '$endNo E' : 'E$endNo';
  }

  String get bocciaThrowingBoxSettingsButton =>
      _isJapanese ? '投球場所を設定する' : 'Set throwing boxes';

  String get bocciaReturnToThrowLogButton =>
      _isJapanese ? '投球ログに戻る' : 'Back to throw log';

  String get bocciaThrowingBoxLockedMessage => _isJapanese
      ? '投球ログ入力後は投球場所を変更できません'
      : 'Throwing boxes cannot be changed after throw logs are entered.';

  String get bocciaUnusedThrowingBoxLabel => _isJapanese ? '未使用' : 'Unused';

  String bocciaDefaultParticipantName(int playerSlot) {
    return _isJapanese ? '参加者$playerSlot' : 'Participant $playerSlot';
  }

  String bocciaThrowCountForBox(int count) {
    return _isJapanese ? '投球数：$count' : 'Throws: $count';
  }

  String get bocciaAddThrowLogTooltip =>
      _isJapanese ? '投球ログを追加' : 'Add throw log';

  String get bocciaThrowOrderTitle => _isJapanese ? '投球順' : 'Throw order';

  String get bocciaNoThrowLogsMessage =>
      _isJapanese ? 'まだ投球ログはありません。' : 'No throw logs yet.';

  String get clearBocciaEndThrowLogsButton =>
      _isJapanese ? 'このエンドの履歴をクリア' : 'Clear this end';

  String bocciaThrowOrderItem({
    required int throwNo,
    required String playerName,
    required String sideLabel,
    required int boxNo,
  }) {
    return _isJapanese
        ? '$throwNo. $playerName（$sideLabel / Box $boxNo）'
        : '$throwNo. $playerName ($sideLabel / Box $boxNo)';
  }

  String get removeLastBocciaThrowLogTooltip =>
      _isJapanese ? '最後の投球を取り消す' : 'Undo last throw';

  String get bocciaTotalLabel => _isJapanese ? '合計' : 'Total';

  String get saveBocciaScoreButton => _isJapanese ? '保存' : 'Save';

  String get closeBocciaScoreDialogButton => _isJapanese ? '閉じる' : 'Close';

  String get bocciaScoreSavedMessage => _isJapanese ? '保存しました' : 'Saved.';

  String get bocciaScoreUnsavedChangesMessage =>
      _isJapanese ? '未保存の変更があります' : 'There are unsaved changes.';

  String get bocciaScoreDiscardChangesTitle =>
      _isJapanese ? '未保存の変更があります' : 'Unsaved changes';

  String get bocciaScoreDiscardChangesBody => _isJapanese
      ? '保存していないスコア変更があります。閉じますか？'
      : 'There are unsaved score changes. Do you want to close?';

  String get clearBocciaEndThrowLogsDialogTitle =>
      _isJapanese ? 'このエンドの投球履歴をクリアしますか？' : 'Clear throw logs for this end?';

  String get clearBocciaEndThrowLogsDialogBody => _isJapanese
      ? '選択中エンドの投球順と投球数を削除します。この操作は元に戻せません。'
      : 'This will delete the throw order and throw counts for the selected end. This action cannot be undone.';

  String get cancelClearBocciaEndThrowLogsButton =>
      _isJapanese ? 'キャンセル' : 'Cancel';

  String get confirmClearBocciaEndThrowLogsButton =>
      _isJapanese ? 'クリア' : 'Clear';

  String get returnToBocciaScoreInputButton =>
      _isJapanese ? '入力に戻る' : 'Back to input';

  String get discardBocciaScoreChangesButton =>
      _isJapanese ? '保存せず閉じる' : 'Close without saving';

  String get saveAndCloseBocciaScoreButton =>
      _isJapanese ? '保存して閉じる' : 'Save and close';
}
