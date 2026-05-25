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
  String get scheduleUpdatedReloadMessage => '対戦表が更新されています。最新の情報に更新します';

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
}
