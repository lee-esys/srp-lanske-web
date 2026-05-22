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
  String get resetInputsButton => '入力項目のリセット';

  @override
  String get generateScheduleButton => '対戦表の生成';
}
