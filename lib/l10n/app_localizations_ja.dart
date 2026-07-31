// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Lanske';

  @override
  String get eventSetupTitle => 'ダブルス乱数表 ver0.1';

  @override
  String get topPageMenu => 'TOPへ';

  @override
  String get matchTableList => '対戦表一覧';

  @override
  String get supportMenuTitle => 'サポート';

  @override
  String get supportMenuSubtitle => 'フィードバックもこちらから';

  @override
  String get eventSetupInstruction => 'URLを貼るか、手動で面数・人数を入力してください。';

  @override
  String get eventSetupSupportedConditions =>
      'ver0.1では、1面4〜7人 / 2面8〜15人に対応しています。';

  @override
  String get courtCountLabel => '面数';

  @override
  String get playerCountLabel => '人数';

  @override
  String get decrementCourtCountTooltip => '面数を減らす';

  @override
  String get incrementCourtCountTooltip => '面数を増やす';

  @override
  String get decrementPlayerCountTooltip => '人数を減らす';

  @override
  String get incrementPlayerCountTooltip => '人数を増やす';

  @override
  String playerCountRangeHelp(int minPlayerCount, int maxPlayerCount) {
    return '人数は $minPlayerCount 人以上、$maxPlayerCount 人以下で入力してください。';
  }

  @override
  String get loadingEventInfo => 'イベント情報を取得中...';

  @override
  String get enterUrlMessage => 'URLを入力してください';

  @override
  String get enterTennisbearEventUrlMessage => 'テニスベアのイベントURLを入力してください';

  @override
  String get eventInfoLoadedMessage => 'イベント情報を取得しました';

  @override
  String get eventInfoPartiallyLoadedMessage =>
      'イベント情報を取得しました（一部情報は取得できませんでした）';

  @override
  String get eventInfoLoadFailedMessage => '取得できませんでした。URLを確認して再度お試しください';

  @override
  String get clipboardUrlNotFoundMessage => 'クリップボードにURLがありません';

  @override
  String get pasteTennisbearEventUrlMessage => 'テニスベアのイベントURLを貼り付けてください';

  @override
  String get tennisbearEventUrlLabel => 'テニスベアのイベントURL';

  @override
  String get tennisbearEventUrlHelper => '例: テニスベアのイベント詳細URL';

  @override
  String get tennisbearEventUrlError => 'テニスベアのイベントURLを入力してください';

  @override
  String get clearUrlTooltip => 'URLをクリア';

  @override
  String get pasteButton => '貼り付け';

  @override
  String get importButton => '取り込み';

  @override
  String get eventNameLabel => 'イベント名';

  @override
  String get playerDisplayNameSectionTitle => '参加者表示名';

  @override
  String playerDisplayNameInputLabel(int playerNumber, String sourceName) {
    return '参加者$playerNumber：$sourceName';
  }

  @override
  String get resetInputsButton => '入力項目のリセット';

  @override
  String get generateScheduleButton => '対戦表の生成';

  @override
  String get generateButton => '生成';

  @override
  String get regenerateButton => '再生成';

  @override
  String get adoptingScheduleButton => '採用中';

  @override
  String get adoptScheduleButton => 'この対戦表を採用';

  @override
  String get cannotRegenerateAdoptedScheduleMessage => '採用済みのため再生成できません';

  @override
  String get regenerateConfirmTitle => '再生成しますか？';

  @override
  String get regenerateConfirmBody =>
      '現在表示している対戦表を新しい対戦表に差し替えます。\n共有URLから表示される未採用の対戦表も、再生成後の内容に更新されます。';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get regenerateActionButton => '再生成する';

  @override
  String get scheduleNotFoundMessage => '対戦表が見つかりません';

  @override
  String get shareUrlCreateFailedMessage => 'URLを作成できませんでした';

  @override
  String get shareUrlCopiedMessage => 'URLをコピーしました';

  @override
  String generateScheduleFailedMessage(String error) {
    return '対戦表を生成できませんでした: $error';
  }

  @override
  String get reloadScheduleMissingIdMessage =>
      '再取得する generated_schedule_id がありません';

  @override
  String reloadScheduleFailedMessage(String error) {
    return '対戦表を取得できませんでした: $error';
  }

  @override
  String get adoptScheduleMissingIdMessage =>
      '採用する generated_schedule_id がありません';

  @override
  String get adoptEventMissingMessage => '採用するイベント情報がありません';

  @override
  String get alreadyAdoptedScheduleMessage => 'すでに採用済みです';

  @override
  String get scheduleUpdatedReloadMessage => '対戦表が更新されていたため、最新の対戦表を表示しました。';

  @override
  String get adoptScheduleCompletedMessage => 'この対戦表を採用しました';

  @override
  String adoptScheduleFailedMessage(String error) {
    return '対戦表を採用できませんでした: $error';
  }

  @override
  String schedulePlayersTitle(int courtCount, int playerCount) {
    return '面数: $courtCount　　参加者: $playerCount人';
  }

  @override
  String get matchTableTitle => '対戦表';

  @override
  String get errorTitle => 'エラー';

  @override
  String get copyUrlButton => 'URLをコピー';

  @override
  String get refreshLatestButton => '最新の情報に更新';

  @override
  String get shareUrlDescription => 'URLを共有して対戦表をみんなで確認しましょう٩( ᐛ )و';

  @override
  String get playersTitle => '参加者';

  @override
  String get noPlayersMessage => '参加者情報がありません';

  @override
  String get scheduleNotLoadedMessage => '対戦表を取得できていません';

  @override
  String get scheduleDataEmptyMessage => '対戦表データがありません';

  @override
  String get restLabel => '休憩';

  @override
  String restCountLabel(int restCount) {
    return '$restCount人';
  }

  @override
  String lastOpenedAtLabel(String lastOpenedAt) {
    return '最終表示: $lastOpenedAt';
  }

  @override
  String get removePlayerTooltip => 'この参加者を削除';

  @override
  String get cannotRemovePlayerTooltip => '最低人数のため削除できません';

  @override
  String courtDisplaySummary(String courtLabels) {
    return 'コート表示: $courtLabels';
  }

  @override
  String get changeCourtDisplayButton => '変更';

  @override
  String get displaySettingsDialogTitle => '表示の変更';

  @override
  String get courtDisplaySectionTitle => 'コート表示';

  @override
  String get courtDisplayPresetNumbers => '1 / 2';

  @override
  String get courtDisplayPresetLetters => 'A / B';

  @override
  String get courtDisplayPresetLeftRight => '左 / 右';

  @override
  String get courtDisplayPresetFrontBack => '前 / 奥';

  @override
  String get courtDisplayPresetCustom => '任意';

  @override
  String courtDisplayInputLabel(int courtNumber) {
    return 'コート$courtNumber';
  }

  @override
  String get courtDisplayEmptyError => 'コート表示を入力してください';

  @override
  String get courtDisplayDuplicateError => 'コート表示が重複しています';

  @override
  String get confirmButton => '決定';

  @override
  String get courtDisplayLabelLeft => '左';

  @override
  String get courtDisplayLabelRight => '右';

  @override
  String get courtDisplayLabelFront => '前';

  @override
  String get courtDisplayLabelBack => '奥';

  @override
  String get shareUrlButton => 'URLを共有';

  @override
  String get closeButton => '閉じる';

  @override
  String get scheduleHistoryEmptyMessage => '対戦表表示履歴がありません';

  @override
  String get clearScheduleHistoryTooltip => '対戦表表示履歴を削除';

  @override
  String get clearScheduleHistoryConfirmTitle => '対戦表表示履歴を削除しますか？';

  @override
  String get clearScheduleHistoryConfirmBody =>
      'この端末の対戦表表示履歴を削除します。削除した履歴は、共有URLまたはQRコードから再度アクセスすると一覧に戻ります。';

  @override
  String get clearScheduleHistoryActionButton => '履歴を削除';

  @override
  String get scheduleHistoryClearedMessage => '対戦表表示履歴を削除しました';

  @override
  String get saveButton => '保存';

  @override
  String get teamSetupMenuTitle => 'らんすけ：チーム';

  @override
  String get teamSetupMenuSubtitle => 'チーム用対戦表を作成';

  @override
  String get teamSetupTitle => 'らんすけ：チーム';

  @override
  String get teamSetupInstruction =>
      '同時進行試合数・参加人数・1チームの目安人数を決めて、チーム用対戦表を作成します。';

  @override
  String get teamSetupSupportedConditions =>
      '初期alphaでは、backend APIで5ラウンド分のチーム対戦表を作成します。';

  @override
  String get teamSetupInputUpperLimitNote =>
      '入力上限: 同時進行試合数5 / 参加人数50 / 1チームの目安人数25 / 1試合で対戦するチーム数25。条件により同時進行数は安全範囲に丸めます。';

  @override
  String get concurrentMatchCountLabel => '同時進行試合数';

  @override
  String get participantCountLabel => '参加人数';

  @override
  String get preferredTeamSizeLabel => 'チームの人数';

  @override
  String get teamsPerMatchLabel => '1試合の対戦チーム数';

  @override
  String get decrementConcurrentMatchCountTooltip => '同時進行試合数を減らす';

  @override
  String get incrementConcurrentMatchCountTooltip => '同時進行試合数を増やす';

  @override
  String get decrementParticipantCountTooltip => '参加人数を減らす';

  @override
  String get incrementParticipantCountTooltip => '参加人数を増やす';

  @override
  String get decrementPreferredTeamSizeTooltip => '1チームの目安人数を減らす';

  @override
  String get incrementPreferredTeamSizeTooltip => '1チームの目安人数を増やす';

  @override
  String get decrementTeamsPerMatchTooltip => '1試合で対戦するチーム数を減らす';

  @override
  String get incrementTeamsPerMatchTooltip => '1試合で対戦するチーム数を増やす';

  @override
  String teamSetupRangeHelp(int minValue, int maxValue) {
    return '$minValue〜$maxValue の範囲で選択できます。';
  }

  @override
  String teamCountSummary(int teamCount) {
    return '$teamCountチーム';
  }

  @override
  String get teamCountSummaryHelp => '参加人数と1チームの目安人数から自動計算します。';

  @override
  String teamDistributionSummary(String summary) {
    return '内訳: $summary';
  }

  @override
  String teamDistributionItem(int memberCount, int teamCount) {
    return '$memberCount人×$teamCountチーム';
  }

  @override
  String get teamDistributionSummaryHelp => '余りがある場合は、一部チームの人数が1人少なくなります。';

  @override
  String get teamParticipantInputTitle => '参加者名の取り込み';

  @override
  String get teamParticipantInputButton => '参加者入力';

  @override
  String get teamParticipantInputDescription =>
      '改行区切りで参加者名を貼り付けて反映できます。カンマ・読点・タブ区切りも簡易対応します。';

  @override
  String get teamParticipantInputLabel => '参加者名';

  @override
  String get teamParticipantInputHint => '例:\n田中\n佐藤\n鈴木';

  @override
  String get applyParticipantNamesButton => '参加者名を反映';

  @override
  String participantNameCountStatus(int nameCount, int participantCount) {
    return '入力済み: $nameCount人 / 参加人数: $participantCount人';
  }

  @override
  String participantNamesAppliedMessage(int nameCount) {
    return '$nameCount人の参加者名を反映しました';
  }

  @override
  String participantNamesTrimmedMessage(int maxCount) {
    return '$maxCount人まで取り込みました。超過分は省略しました。';
  }

  @override
  String get participantNamesTooFewMessage => '参加者名は2人以上入力してください。';

  @override
  String get participantNamesEmptyMessage => '参加者名を入力してください。';

  @override
  String get resetTeamSetupButton => '入力項目のリセット';

  @override
  String get generateTeamScheduleButton => 'チーム対戦表を作成';

  @override
  String get teamSetupAlphaNoticeTitle => 'alpha確認中';

  @override
  String get teamSetupAlphaNoticeBody =>
      '作成後、backend API の生成結果を保存し、共有URLから再表示できます。チーム変更・スコア入力はまだ未実装です。';

  @override
  String get teamSetupCreatedMessage => 'チーム用セットアップ条件を作成しました';

  @override
  String get teamScheduleTitle => 'チーム対戦表';

  @override
  String get teamScheduleListTitle => 'チーム対戦表一覧';

  @override
  String get teamScheduleListEmptyTitle => 'チーム対戦表はまだありません';

  @override
  String get teamScheduleListEmptyMessage =>
      'チーム対戦表を作成または共有URLから開くと、この端末の一覧に表示されます。';

  @override
  String get teamScheduleListLoadErrorTitle => '一覧を読み込めませんでした';

  @override
  String get teamScheduleListLoadErrorMessage =>
      '端末内の保存履歴を確認できませんでした。もう一度お試しください。';

  @override
  String get teamScheduleUntitledEvent => 'タイトル未設定のチーム対戦表';

  @override
  String teamScheduleListShareId(String shareId) {
    return '共有ID: $shareId';
  }

  @override
  String teamScheduleListTeamCount(int teamCount) {
    return '$teamCountチーム';
  }

  @override
  String teamScheduleListMemberCount(int memberCount) {
    return '$memberCount人';
  }

  @override
  String teamScheduleListUpdatedAt(String updatedAt) {
    return '更新: $updatedAt';
  }

  @override
  String get teamNavigationMenuTooltip => 'チーム用メニューを開く';

  @override
  String get teamNavigationTitle => 'チーム乱数表';

  @override
  String get teamNavigationSubtitle => 'チーム用メニュー';

  @override
  String get teamNavigationHome => 'チームTOP';

  @override
  String get teamNavigationScheduleList => '対戦表一覧';

  @override
  String get teamNavigationSupport => 'サポート';

  @override
  String get teamNavigationServiceList => 'サービス一覧';

  @override
  String get teamNavigationDoublesScheduler => 'ダブルス乱数表';

  @override
  String get defaultTeamScheduleEventTitle => 'チーム練習会';

  @override
  String get teamScheduleBulkEditTitle => 'まとめて編集';

  @override
  String get teamScheduleBulkEditButton => 'まとめて編集';

  @override
  String get teamScheduleEventTitleLabel => 'イベントタイトル';

  @override
  String get teamScheduleMemoLabel => 'メモ';

  @override
  String get teamScheduleHasMemoTooltip => 'メモあり';

  @override
  String get teamScheduleBulkEditTeamsSection => 'チーム名';

  @override
  String get teamScheduleBulkEditMembersSection => 'メンバー名';

  @override
  String teamScheduleTeamNameLabel(int teamSlot) {
    return 'チーム$teamSlot';
  }

  @override
  String defaultTeamMemberName(int memberNo) {
    return '参加者$memberNo';
  }

  @override
  String defaultTeamName(int teamNo) {
    return 'チーム$teamNo';
  }

  @override
  String teamScheduleSummary(
      int teamCount, int memberCount, int concurrentMatchCount) {
    return '$teamCountチーム / $memberCount人 / $concurrentMatchCount同時進行';
  }

  @override
  String get teamScheduleBackendDataNotice =>
      'backend API の生成結果を保存して表示しています。表示名はこの画面内で編集できます。';

  @override
  String get creatingTeamScheduleMessage => 'チーム対戦表を作成・保存中です…';

  @override
  String get restoringTeamScheduleMessage => '保存済みのチーム対戦表を読み込み中です…';

  @override
  String get savingTeamScheduleDisplayMessage => '表示名を保存中です…';

  @override
  String get teamScheduleGenerateFailedTitle => 'チーム対戦表の作成に失敗しました';

  @override
  String get teamScheduleGenerateFailedBody =>
      'backend API または Firestore 保存の応答を確認してください。';

  @override
  String teamScheduleGenerateFailedBodyWithDetail(String detail) {
    return 'backend API または Firestore 保存の応答を確認してください。\n\n$detail';
  }

  @override
  String get teamScheduleRestoreFailedTitle => 'チーム対戦表の読み込みに失敗しました';

  @override
  String get teamScheduleRestoreFailedBody => '共有IDまたは保存済みデータを確認してください。';

  @override
  String teamScheduleRestoreFailedBodyWithDetail(String detail) {
    return '共有IDまたは保存済みデータを確認してください。\n\n$detail';
  }

  @override
  String teamScheduleDisplaySaveFailedMessage(String detail) {
    return '表示名の保存に失敗しました: $detail';
  }

  @override
  String get retryTeamScheduleGenerateButton => 'もう一度作成';

  @override
  String get retryTeamScheduleRestoreButton => 'もう一度読み込む';

  @override
  String get teamScheduleShareTitle => '共有URL';

  @override
  String get teamScheduleShareDescription => 'このURLを共有すると、保存済みのチーム対戦表を開き直せます。';

  @override
  String teamScheduleShareIdLabel(String shareId) {
    return '共有ID: $shareId';
  }

  @override
  String get copyTeamScheduleShareUrlButton => '共有URLをコピー';

  @override
  String get teamScheduleShareUrlCopiedMessage => '共有URLをコピーしました';

  @override
  String get nextTeamMatchTitle => '次の対戦';

  @override
  String teamRoundTitle(int roundNo) {
    return '第$roundNoラウンド';
  }

  @override
  String teamCourtTitle(int courtNo) {
    return 'コート$courtNo';
  }

  @override
  String teamCourtMatchTitle(int courtNo, String matchTitle) {
    return 'コート$courtNo: $matchTitle';
  }

  @override
  String get teamListTitle => 'チーム一覧';

  @override
  String teamChoiceLabel(String teamName, int memberCount) {
    return '$teamName ($memberCount人)';
  }

  @override
  String selectedTeamMembersTitle(String teamName) {
    return '$teamName のメンバー';
  }

  @override
  String get teamMatchVsSeparator => ' vs ';

  @override
  String get teamMatchGroupSeparator => ' / ';

  @override
  String get teamMatchVsLabel => 'vs';

  @override
  String get editTeamScheduleEventTitleTooltip => 'イベントタイトルを編集';

  @override
  String get editTeamNameTooltip => 'チーム名を編集';

  @override
  String get editTeamMemberNameTooltip => 'メンバー表示名を編集';

  @override
  String get editTeamScheduleEventTitleDialogTitle => 'イベントタイトルを編集';

  @override
  String editTeamNameDialogTitle(String teamName) {
    return '$teamName を編集';
  }

  @override
  String editTeamMemberNameDialogTitle(String memberName) {
    return '$memberName を編集';
  }

  @override
  String get displayNameInputLabel => '表示名';

  @override
  String get teamScheduleSportSectionTitle => 'スコア入力';

  @override
  String get teamScheduleSportNoneLabel => '未選択';

  @override
  String get teamScheduleSportBocciaLabel => 'ボッチャ';

  @override
  String get teamScheduleSportHelp => '競技を選択すると、対戦カードからスコアを入力できます。';

  @override
  String get savingTeamScheduleScoresMessage => 'スコアを保存中です…';

  @override
  String teamScheduleScoresSaveFailedMessage(String detail) {
    return 'スコアの保存に失敗しました: $detail';
  }

  @override
  String get teamScheduleConcurrentEditNotice =>
      '複数端末で同時に編集すると、保存内容が意図どおり反映されない場合があります。';

  @override
  String get refreshingTeamScheduleScoresMessage => '最新のスコア情報を取得しています...';

  @override
  String get bocciaScoreRefreshedMessage => '最新の情報に更新しました';

  @override
  String get refreshBocciaScoreFailedMessage => '最新の情報を取得できませんでした';

  @override
  String get refreshBocciaScoreDiscardChangesTitle => '未保存の変更を破棄して更新しますか？';

  @override
  String get refreshBocciaScoreDiscardChangesBody =>
      '最新の情報に更新すると、保存していない入力内容は破棄されます。';

  @override
  String get confirmRefreshBocciaScoreButton => '更新する';

  @override
  String get selectSportBeforeScoreInputMessage => '先に競技を選択してください。';

  @override
  String get unsupportedBocciaMatchMessage => 'ボッチャのスコア入力は2チーム対戦のみ対応しています。';

  @override
  String get inputBocciaScoreButton => 'スコア入力';

  @override
  String get editBocciaScoreButton => 'スコア編集';

  @override
  String bocciaScoreSummary(
      String redTeamName, int redScore, int blueScore, String blueTeamName) {
    return '$redTeamName $redScore - $blueScore $blueTeamName';
  }

  @override
  String get bocciaScoreDialogTitle => 'ボッチャ スコア入力';

  @override
  String bocciaScoreDialogMatchTitle(String redTeamName, String blueTeamName) {
    return '$redTeamName vs $blueTeamName';
  }

  @override
  String bocciaThrowLogTitle(int endNo) {
    return '${endNo}E 投球ログ';
  }

  @override
  String get bocciaThrowLogHelp => '投球場所に設定された参加者の＋を押すと、このエンドの投球ログに追加します。';

  @override
  String bocciaThrowCountSummary(int redCount, int blueCount) {
    return '投球数：赤：$redCount　青：$blueCount';
  }

  @override
  String bocciaThrowCountProgress(int count, int maxCount) {
    return '$count / $maxCount投';
  }

  @override
  String get bocciaFirstTeamLabel => '先攻';

  @override
  String get bocciaSecondTeamLabel => '後攻';

  @override
  String get bocciaRedSideLabel => '赤';

  @override
  String get bocciaBlueSideLabel => '青';

  @override
  String get swapBocciaOrderButton => '先攻 🔁 後攻';

  @override
  String get swapBocciaOrderTooltip => '先攻と後攻をスコアごと入れ替える';

  @override
  String bocciaEndLabel(int endNo) {
    return '$endNo E';
  }

  @override
  String get bocciaThrowingBoxSettingsButton => '投球場所を設定する';

  @override
  String get bocciaReturnToThrowLogButton => '投球ログに戻る';

  @override
  String get bocciaThrowingBoxLockedMessage => '投球ログ入力後は投球場所を変更できません';

  @override
  String get bocciaUnusedThrowingBoxLabel => '未使用';

  @override
  String bocciaDefaultParticipantName(int playerSlot) {
    return '参加者$playerSlot';
  }

  @override
  String bocciaThrowCountForBox(int count) {
    return '投球数：$count';
  }

  @override
  String get bocciaAddThrowLogTooltip => '投球ログを追加';

  @override
  String get bocciaThrowOrderTitle => '投球順';

  @override
  String get bocciaNoThrowLogsMessage => 'まだ投球ログはありません。';

  @override
  String get clearBocciaEndThrowLogsButton => 'このエンドの履歴をクリア';

  @override
  String bocciaThrowOrderItem(
      int throwNo, String playerName, String sideLabel, int boxNo) {
    return '$throwNo. $playerName（$sideLabel / Box $boxNo）';
  }

  @override
  String get removeLastBocciaThrowLogTooltip => '最後の投球を取り消す';

  @override
  String get bocciaTotalLabel => '合計';

  @override
  String get bocciaScoreSavedMessage => '保存しました';

  @override
  String get bocciaScoreUnsavedChangesMessage => '未保存の変更があります';

  @override
  String get bocciaScoreDiscardChangesTitle => '未保存の変更があります';

  @override
  String get bocciaScoreDiscardChangesBody => '保存していないスコア変更があります。閉じますか？';

  @override
  String get clearBocciaEndThrowLogsDialogTitle => 'このエンドの投球履歴をクリアしますか？';

  @override
  String get clearBocciaEndThrowLogsDialogBody =>
      '選択中エンドの投球順と投球数を削除します。この操作は元に戻せません。';

  @override
  String get confirmClearBocciaEndThrowLogsButton => 'クリア';

  @override
  String get returnToBocciaScoreInputButton => '入力に戻る';

  @override
  String get discardBocciaScoreChangesButton => '保存せず閉じる';

  @override
  String get saveAndCloseBocciaScoreButton => '保存して閉じる';

  @override
  String get doublesMatchEditTitle => '試合状態・最終スコア';

  @override
  String get doublesMatchStatusScheduledLabel => '試合前';

  @override
  String get doublesMatchStatusInProgressLabel => '試合中';

  @override
  String get doublesMatchStatusCompletedLabel => '終了';

  @override
  String get doublesMatchScorePickerTitle => 'スコアを選択';

  @override
  String get doublesMatchScoreUnsetLabel => 'スコアを未入力に戻す';

  @override
  String get doublesMatchStartTimeLabel => '開始時間';

  @override
  String get doublesMatchEndTimeLabel => '終了時間';

  @override
  String get doublesMatchSetCurrentTimeTooltip => '現在時刻を設定';

  @override
  String get doublesMatchNoteLabel => '試合メモ';

  @override
  String get doublesMatchSaveButton => '保存';

  @override
  String get doublesMatchWinnerLabel => '勝ち';

  @override
  String get doublesMatchLoserLabel => '負け';

  @override
  String get doublesMatchDrawLabel => '引き分け';

  @override
  String get doublesMatchSavedMessage => '試合情報を保存しました';

  @override
  String get doublesMatchRefreshedMessage => '試合情報を更新しました';

  @override
  String get doublesMatchConflictMessage => '別の端末で試合情報が更新されています。最新情報を取得してください。';

  @override
  String get doublesMatchIncompleteScoreMessage =>
      '両側のスコアを入力するか、両方とも未入力にしてください。';

  @override
  String get doublesMatchTimeOrderErrorMessage => '終了時間は開始時間以降にしてください。';

  @override
  String get doublesMatchUnavailableMessage => 'この試合の入力に必要な対戦表情報がありません。';

  @override
  String get doublesMatchScheduleChangedMessage =>
      '対戦表が別の端末で更新されています。最新の対戦表を読み込んでください。';

  @override
  String doublesMatchSaveFailedMessage(String error) {
    return '試合情報を保存できませんでした: $error';
  }
}
