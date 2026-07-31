import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja')
  ];

  /// Application title.
  ///
  /// In ja, this message translates to:
  /// **'Lanske'**
  String get appTitle;

  /// Title shown on doubles scheduler pages.
  ///
  /// In ja, this message translates to:
  /// **'らんすけ：ダブルス乱数表'**
  String get eventSetupTitle;

  /// Menu item label for returning to the top page.
  ///
  /// In ja, this message translates to:
  /// **'TOPへ'**
  String get topPageMenu;

  /// Menu item label for the saved/generated match table list.
  ///
  /// In ja, this message translates to:
  /// **'対戦表一覧'**
  String get matchTableList;

  /// Menu item title for opening the support page.
  ///
  /// In ja, this message translates to:
  /// **'サポート'**
  String get supportMenuTitle;

  /// Menu item subtitle for the support page link.
  ///
  /// In ja, this message translates to:
  /// **'フィードバックもこちらから'**
  String get supportMenuSubtitle;

  /// Instruction text on the event setup page.
  ///
  /// In ja, this message translates to:
  /// **'URLを貼るか、手動で面数・人数を入力してください。'**
  String get eventSetupInstruction;

  /// Short note about supported court and player count conditions.
  ///
  /// In ja, this message translates to:
  /// **'ver0.1では、1面4〜7人 / 2面8〜15人に対応しています。'**
  String get eventSetupSupportedConditions;

  /// Label for court count input.
  ///
  /// In ja, this message translates to:
  /// **'面数'**
  String get courtCountLabel;

  /// Label for player count input.
  ///
  /// In ja, this message translates to:
  /// **'人数'**
  String get playerCountLabel;

  /// Tooltip for decreasing court count.
  ///
  /// In ja, this message translates to:
  /// **'面数を減らす'**
  String get decrementCourtCountTooltip;

  /// Tooltip for increasing court count.
  ///
  /// In ja, this message translates to:
  /// **'面数を増やす'**
  String get incrementCourtCountTooltip;

  /// Tooltip for decreasing player count.
  ///
  /// In ja, this message translates to:
  /// **'人数を減らす'**
  String get decrementPlayerCountTooltip;

  /// Tooltip for increasing player count.
  ///
  /// In ja, this message translates to:
  /// **'人数を増やす'**
  String get incrementPlayerCountTooltip;

  /// Help text that shows the valid player count range.
  ///
  /// In ja, this message translates to:
  /// **'人数は {minPlayerCount} 人以上、{maxPlayerCount} 人以下で入力してください。'**
  String playerCountRangeHelp(int minPlayerCount, int maxPlayerCount);

  /// Loading message shown while importing event information.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報を取得中...'**
  String get loadingEventInfo;

  /// Snack bar message shown when URL input is empty.
  ///
  /// In ja, this message translates to:
  /// **'URLを入力してください'**
  String get enterUrlMessage;

  /// Snack bar message shown when the URL is not a TennisBear event URL.
  ///
  /// In ja, this message translates to:
  /// **'テニスベアのイベントURLを入力してください'**
  String get enterTennisbearEventUrlMessage;

  /// Snack bar message shown when event information was imported successfully.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報を取得しました'**
  String get eventInfoLoadedMessage;

  /// Snack bar message shown when event information was imported with warnings.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報を取得しました（一部情報は取得できませんでした）'**
  String get eventInfoPartiallyLoadedMessage;

  /// Snack bar message shown when event information import failed.
  ///
  /// In ja, this message translates to:
  /// **'取得できませんでした。URLを確認して再度お試しください'**
  String get eventInfoLoadFailedMessage;

  /// Snack bar message shown when clipboard has no URL.
  ///
  /// In ja, this message translates to:
  /// **'クリップボードにURLがありません'**
  String get clipboardUrlNotFoundMessage;

  /// Snack bar message shown when pasted text is not a TennisBear event URL.
  ///
  /// In ja, this message translates to:
  /// **'テニスベアのイベントURLを貼り付けてください'**
  String get pasteTennisbearEventUrlMessage;

  /// Input label for TennisBear event URL.
  ///
  /// In ja, this message translates to:
  /// **'テニスベアのイベントURL'**
  String get tennisbearEventUrlLabel;

  /// Helper text example for TennisBear event URL input.
  ///
  /// In ja, this message translates to:
  /// **'例: テニスベアのイベント詳細URL'**
  String get tennisbearEventUrlHelper;

  /// Validation error for TennisBear event URL input.
  ///
  /// In ja, this message translates to:
  /// **'テニスベアのイベントURLを入力してください'**
  String get tennisbearEventUrlError;

  /// Tooltip for clearing the URL input.
  ///
  /// In ja, this message translates to:
  /// **'URLをクリア'**
  String get clearUrlTooltip;

  /// Button label for pasting text from clipboard.
  ///
  /// In ja, this message translates to:
  /// **'貼り付け'**
  String get pasteButton;

  /// Button label for importing event information.
  ///
  /// In ja, this message translates to:
  /// **'取り込み'**
  String get importButton;

  /// Input label for event name.
  ///
  /// In ja, this message translates to:
  /// **'イベント名'**
  String get eventNameLabel;

  /// Section title for player display name inputs.
  ///
  /// In ja, this message translates to:
  /// **'参加者表示名'**
  String get playerDisplayNameSectionTitle;

  /// Input label for each player display name field.
  ///
  /// In ja, this message translates to:
  /// **'参加者{playerNumber}：{sourceName}'**
  String playerDisplayNameInputLabel(int playerNumber, String sourceName);

  /// Button label for resetting input fields.
  ///
  /// In ja, this message translates to:
  /// **'入力項目のリセット'**
  String get resetInputsButton;

  /// Button label for generating a match table.
  ///
  /// In ja, this message translates to:
  /// **'対戦表の生成'**
  String get generateScheduleButton;

  /// Short button label for generating a schedule.
  ///
  /// In ja, this message translates to:
  /// **'生成'**
  String get generateButton;

  /// Short button label for regenerating a schedule.
  ///
  /// In ja, this message translates to:
  /// **'再生成'**
  String get regenerateButton;

  /// Button label shown while adopting a schedule.
  ///
  /// In ja, this message translates to:
  /// **'採用中'**
  String get adoptingScheduleButton;

  /// Button label for adopting the currently displayed schedule.
  ///
  /// In ja, this message translates to:
  /// **'この対戦表を採用'**
  String get adoptScheduleButton;

  /// Message shown when regeneration is blocked because the schedule was adopted.
  ///
  /// In ja, this message translates to:
  /// **'採用済みのため再生成できません'**
  String get cannotRegenerateAdoptedScheduleMessage;

  /// Dialog title for confirming schedule regeneration.
  ///
  /// In ja, this message translates to:
  /// **'再生成しますか？'**
  String get regenerateConfirmTitle;

  /// Dialog body for confirming schedule regeneration.
  ///
  /// In ja, this message translates to:
  /// **'現在表示している対戦表を新しい対戦表に差し替えます。\n共有URLから表示される未採用の対戦表も、再生成後の内容に更新されます。'**
  String get regenerateConfirmBody;

  /// Generic cancel button label.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancelButton;

  /// Dialog action button label for regenerating a schedule.
  ///
  /// In ja, this message translates to:
  /// **'再生成する'**
  String get regenerateActionButton;

  /// Message shown when the saved schedule cannot be found.
  ///
  /// In ja, this message translates to:
  /// **'対戦表が見つかりません'**
  String get scheduleNotFoundMessage;

  /// Message shown when a share URL cannot be created.
  ///
  /// In ja, this message translates to:
  /// **'URLを作成できませんでした'**
  String get shareUrlCreateFailedMessage;

  /// Message shown when the share URL was copied.
  ///
  /// In ja, this message translates to:
  /// **'URLをコピーしました'**
  String get shareUrlCopiedMessage;

  /// Error message shown when schedule generation failed.
  ///
  /// In ja, this message translates to:
  /// **'対戦表を生成できませんでした: {error}'**
  String generateScheduleFailedMessage(String error);

  /// Error message shown when no generated schedule id is available for reload.
  ///
  /// In ja, this message translates to:
  /// **'再取得する generated_schedule_id がありません'**
  String get reloadScheduleMissingIdMessage;

  /// Error message shown when reloading a schedule failed.
  ///
  /// In ja, this message translates to:
  /// **'対戦表を取得できませんでした: {error}'**
  String reloadScheduleFailedMessage(String error);

  /// Message shown when no generated schedule id is available for adoption.
  ///
  /// In ja, this message translates to:
  /// **'採用する generated_schedule_id がありません'**
  String get adoptScheduleMissingIdMessage;

  /// Message shown when event information for adoption is missing.
  ///
  /// In ja, this message translates to:
  /// **'採用するイベント情報がありません'**
  String get adoptEventMissingMessage;

  /// Message shown when the schedule has already been adopted.
  ///
  /// In ja, this message translates to:
  /// **'すでに採用済みです'**
  String get alreadyAdoptedScheduleMessage;

  /// Message shown when the displayed schedule is outdated.
  ///
  /// In ja, this message translates to:
  /// **'対戦表が更新されていたため、最新の対戦表を表示しました。'**
  String get scheduleUpdatedReloadMessage;

  /// Message shown when schedule adoption completed.
  ///
  /// In ja, this message translates to:
  /// **'この対戦表を採用しました'**
  String get adoptScheduleCompletedMessage;

  /// Error message shown when schedule adoption failed.
  ///
  /// In ja, this message translates to:
  /// **'対戦表を採用できませんでした: {error}'**
  String adoptScheduleFailedMessage(String error);

  /// Title for player list showing court count and player count.
  ///
  /// In ja, this message translates to:
  /// **'面数: {courtCount}　　参加者: {playerCount}人'**
  String schedulePlayersTitle(int courtCount, int playerCount);

  /// Section title for the match table.
  ///
  /// In ja, this message translates to:
  /// **'対戦表'**
  String get matchTableTitle;

  /// Generic error section title.
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get errorTitle;

  /// Button label for copying a share URL.
  ///
  /// In ja, this message translates to:
  /// **'URLをコピー'**
  String get copyUrlButton;

  /// Button label for refreshing the latest schedule information.
  ///
  /// In ja, this message translates to:
  /// **'最新の情報に更新'**
  String get refreshLatestButton;

  /// Short description encouraging users to share the schedule URL.
  ///
  /// In ja, this message translates to:
  /// **'URLを共有して対戦表をみんなで確認しましょう٩( ᐛ )و'**
  String get shareUrlDescription;

  /// Section title for player information.
  ///
  /// In ja, this message translates to:
  /// **'参加者'**
  String get playersTitle;

  /// Message shown when no player information is available.
  ///
  /// In ja, this message translates to:
  /// **'参加者情報がありません'**
  String get noPlayersMessage;

  /// Message shown when no schedule response is loaded.
  ///
  /// In ja, this message translates to:
  /// **'対戦表を取得できていません'**
  String get scheduleNotLoadedMessage;

  /// Message shown when the schedule response contains no rounds.
  ///
  /// In ja, this message translates to:
  /// **'対戦表データがありません'**
  String get scheduleDataEmptyMessage;

  /// Label for resting players.
  ///
  /// In ja, this message translates to:
  /// **'休憩'**
  String get restLabel;

  /// Short label showing the number of resting players.
  ///
  /// In ja, this message translates to:
  /// **'{restCount}人'**
  String restCountLabel(int restCount);

  /// Label showing when a saved schedule was last opened.
  ///
  /// In ja, this message translates to:
  /// **'最終表示: {lastOpenedAt}'**
  String lastOpenedAtLabel(String lastOpenedAt);

  /// Tooltip for removing a player input field.
  ///
  /// In ja, this message translates to:
  /// **'この参加者を削除'**
  String get removePlayerTooltip;

  /// Tooltip shown when a player input field cannot be removed because the minimum player count has been reached.
  ///
  /// In ja, this message translates to:
  /// **'最低人数のため削除できません'**
  String get cannotRemovePlayerTooltip;

  /// Summary text for current court display labels.
  ///
  /// In ja, this message translates to:
  /// **'コート表示: {courtLabels}'**
  String courtDisplaySummary(String courtLabels);

  /// Button label for changing court display settings.
  ///
  /// In ja, this message translates to:
  /// **'変更'**
  String get changeCourtDisplayButton;

  /// Dialog title for display settings.
  ///
  /// In ja, this message translates to:
  /// **'表示の変更'**
  String get displaySettingsDialogTitle;

  /// Section title for court display settings.
  ///
  /// In ja, this message translates to:
  /// **'コート表示'**
  String get courtDisplaySectionTitle;

  /// Preset label for numeric court display.
  ///
  /// In ja, this message translates to:
  /// **'1 / 2'**
  String get courtDisplayPresetNumbers;

  /// Preset label for alphabetic court display.
  ///
  /// In ja, this message translates to:
  /// **'A / B'**
  String get courtDisplayPresetLetters;

  /// Preset label for left-right court display.
  ///
  /// In ja, this message translates to:
  /// **'左 / 右'**
  String get courtDisplayPresetLeftRight;

  /// Preset label for front-back court display.
  ///
  /// In ja, this message translates to:
  /// **'前 / 奥'**
  String get courtDisplayPresetFrontBack;

  /// Preset label for custom court display.
  ///
  /// In ja, this message translates to:
  /// **'任意'**
  String get courtDisplayPresetCustom;

  /// Input label for each court display label.
  ///
  /// In ja, this message translates to:
  /// **'コート{courtNumber}'**
  String courtDisplayInputLabel(int courtNumber);

  /// Validation error shown when a court display label is empty.
  ///
  /// In ja, this message translates to:
  /// **'コート表示を入力してください'**
  String get courtDisplayEmptyError;

  /// Validation error shown when court display labels are duplicated.
  ///
  /// In ja, this message translates to:
  /// **'コート表示が重複しています'**
  String get courtDisplayDuplicateError;

  /// Generic confirmation button label.
  ///
  /// In ja, this message translates to:
  /// **'決定'**
  String get confirmButton;

  /// One-character court display label for left.
  ///
  /// In ja, this message translates to:
  /// **'左'**
  String get courtDisplayLabelLeft;

  /// One-character court display label for right.
  ///
  /// In ja, this message translates to:
  /// **'右'**
  String get courtDisplayLabelRight;

  /// One-character court display label for front.
  ///
  /// In ja, this message translates to:
  /// **'前'**
  String get courtDisplayLabelFront;

  /// One-character court display label for back.
  ///
  /// In ja, this message translates to:
  /// **'奥'**
  String get courtDisplayLabelBack;

  /// Button and dialog title label for sharing a schedule URL.
  ///
  /// In ja, this message translates to:
  /// **'URLを共有'**
  String get shareUrlButton;

  /// Generic close button or tooltip label.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get closeButton;

  /// Message shown when there is no local schedule view history.
  ///
  /// In ja, this message translates to:
  /// **'対戦表表示履歴がありません'**
  String get scheduleHistoryEmptyMessage;

  /// Tooltip for clearing local schedule view history.
  ///
  /// In ja, this message translates to:
  /// **'対戦表表示履歴を削除'**
  String get clearScheduleHistoryTooltip;

  /// Dialog title for confirming local schedule view history deletion.
  ///
  /// In ja, this message translates to:
  /// **'対戦表表示履歴を削除しますか？'**
  String get clearScheduleHistoryConfirmTitle;

  /// Dialog body for confirming local schedule view history deletion.
  ///
  /// In ja, this message translates to:
  /// **'この端末の対戦表表示履歴を削除します。削除した履歴は、共有URLまたはQRコードから再度アクセスすると一覧に戻ります。'**
  String get clearScheduleHistoryConfirmBody;

  /// Dialog action button label for clearing local schedule view history.
  ///
  /// In ja, this message translates to:
  /// **'履歴を削除'**
  String get clearScheduleHistoryActionButton;

  /// Snack bar message shown after local schedule view history was cleared.
  ///
  /// In ja, this message translates to:
  /// **'対戦表表示履歴を削除しました'**
  String get scheduleHistoryClearedMessage;

  /// Generic save button label.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get saveButton;

  /// Team scheduler menu title.
  ///
  /// In ja, this message translates to:
  /// **'らんすけ：チーム'**
  String get teamSetupMenuTitle;

  /// Team scheduler menu subtitle.
  ///
  /// In ja, this message translates to:
  /// **'チーム用対戦表を作成'**
  String get teamSetupMenuSubtitle;

  /// Title shown on the team setup page.
  ///
  /// In ja, this message translates to:
  /// **'らんすけ：チーム'**
  String get teamSetupTitle;

  /// Instruction text shown on the team setup page.
  ///
  /// In ja, this message translates to:
  /// **'同時進行試合数・参加人数・1チームの目安人数を決めて、チーム用対戦表を作成します。'**
  String get teamSetupInstruction;

  /// Short note about supported team scheduler conditions.
  ///
  /// In ja, this message translates to:
  /// **'初期alphaでは、backend APIで5ラウンド分のチーム対戦表を作成します。'**
  String get teamSetupSupportedConditions;

  /// Note about team setup input limits.
  ///
  /// In ja, this message translates to:
  /// **'入力上限: 同時進行試合数5 / 参加人数50 / 1チームの目安人数25 / 1試合で対戦するチーム数25。条件により同時進行数は安全範囲に丸めます。'**
  String get teamSetupInputUpperLimitNote;

  /// Label for simultaneous match count input.
  ///
  /// In ja, this message translates to:
  /// **'同時進行試合数'**
  String get concurrentMatchCountLabel;

  /// Label for participant count input.
  ///
  /// In ja, this message translates to:
  /// **'参加人数'**
  String get participantCountLabel;

  /// Label for preferred team size input.
  ///
  /// In ja, this message translates to:
  /// **'チームの人数'**
  String get preferredTeamSizeLabel;

  /// Label for teams per match input.
  ///
  /// In ja, this message translates to:
  /// **'1試合の対戦チーム数'**
  String get teamsPerMatchLabel;

  /// Tooltip for decreasing simultaneous match count.
  ///
  /// In ja, this message translates to:
  /// **'同時進行試合数を減らす'**
  String get decrementConcurrentMatchCountTooltip;

  /// Tooltip for increasing simultaneous match count.
  ///
  /// In ja, this message translates to:
  /// **'同時進行試合数を増やす'**
  String get incrementConcurrentMatchCountTooltip;

  /// Tooltip for decreasing participant count.
  ///
  /// In ja, this message translates to:
  /// **'参加人数を減らす'**
  String get decrementParticipantCountTooltip;

  /// Tooltip for increasing participant count.
  ///
  /// In ja, this message translates to:
  /// **'参加人数を増やす'**
  String get incrementParticipantCountTooltip;

  /// Tooltip for decreasing preferred team size.
  ///
  /// In ja, this message translates to:
  /// **'1チームの目安人数を減らす'**
  String get decrementPreferredTeamSizeTooltip;

  /// Tooltip for increasing preferred team size.
  ///
  /// In ja, this message translates to:
  /// **'1チームの目安人数を増やす'**
  String get incrementPreferredTeamSizeTooltip;

  /// Tooltip for decreasing teams per match.
  ///
  /// In ja, this message translates to:
  /// **'1試合で対戦するチーム数を減らす'**
  String get decrementTeamsPerMatchTooltip;

  /// Tooltip for increasing teams per match.
  ///
  /// In ja, this message translates to:
  /// **'1試合で対戦するチーム数を増やす'**
  String get incrementTeamsPerMatchTooltip;

  /// Help text showing the valid team setup input range.
  ///
  /// In ja, this message translates to:
  /// **'{minValue}〜{maxValue} の範囲で選択できます。'**
  String teamSetupRangeHelp(int minValue, int maxValue);

  /// Summary showing the calculated team count.
  ///
  /// In ja, this message translates to:
  /// **'{teamCount}チーム'**
  String teamCountSummary(int teamCount);

  /// Help text for the calculated team count.
  ///
  /// In ja, this message translates to:
  /// **'参加人数と1チームの目安人数から自動計算します。'**
  String get teamCountSummaryHelp;

  /// Summary showing the team member distribution.
  ///
  /// In ja, this message translates to:
  /// **'内訳: {summary}'**
  String teamDistributionSummary(String summary);

  /// One item in the calculated team member distribution.
  ///
  /// In ja, this message translates to:
  /// **'{memberCount}人×{teamCount}チーム'**
  String teamDistributionItem(int memberCount, int teamCount);

  /// Help text for uneven team member distribution.
  ///
  /// In ja, this message translates to:
  /// **'余りがある場合は、一部チームの人数が1人少なくなります。'**
  String get teamDistributionSummaryHelp;

  /// Title for the participant name input card.
  ///
  /// In ja, this message translates to:
  /// **'参加者名の取り込み'**
  String get teamParticipantInputTitle;

  /// Short button and dialog heading for participant name input.
  ///
  /// In ja, this message translates to:
  /// **'参加者入力'**
  String get teamParticipantInputButton;

  /// Description for participant name input.
  ///
  /// In ja, this message translates to:
  /// **'改行区切りで参加者名を貼り付けて反映できます。カンマ・読点・タブ区切りも簡易対応します。'**
  String get teamParticipantInputDescription;

  /// Input label for participant names.
  ///
  /// In ja, this message translates to:
  /// **'参加者名'**
  String get teamParticipantInputLabel;

  /// Example participant names shown in the input field.
  ///
  /// In ja, this message translates to:
  /// **'例:\n田中\n佐藤\n鈴木'**
  String get teamParticipantInputHint;

  /// Button label for applying participant names.
  ///
  /// In ja, this message translates to:
  /// **'参加者名を反映'**
  String get applyParticipantNamesButton;

  /// Status showing entered name count and participant count.
  ///
  /// In ja, this message translates to:
  /// **'入力済み: {nameCount}人 / 参加人数: {participantCount}人'**
  String participantNameCountStatus(int nameCount, int participantCount);

  /// Message shown after participant names are applied.
  ///
  /// In ja, this message translates to:
  /// **'{nameCount}人の参加者名を反映しました'**
  String participantNamesAppliedMessage(int nameCount);

  /// Message shown when extra participant names are omitted.
  ///
  /// In ja, this message translates to:
  /// **'{maxCount}人まで取り込みました。超過分は省略しました。'**
  String participantNamesTrimmedMessage(int maxCount);

  /// Validation message for too few participant names.
  ///
  /// In ja, this message translates to:
  /// **'参加者名は2人以上入力してください。'**
  String get participantNamesTooFewMessage;

  /// Validation message for empty participant names.
  ///
  /// In ja, this message translates to:
  /// **'参加者名を入力してください。'**
  String get participantNamesEmptyMessage;

  /// Button label for resetting team setup inputs.
  ///
  /// In ja, this message translates to:
  /// **'入力項目のリセット'**
  String get resetTeamSetupButton;

  /// Button label for creating a team match table.
  ///
  /// In ja, this message translates to:
  /// **'チーム対戦表を作成'**
  String get generateTeamScheduleButton;

  /// Title for the team alpha notice.
  ///
  /// In ja, this message translates to:
  /// **'alpha確認中'**
  String get teamSetupAlphaNoticeTitle;

  /// Body for the team alpha notice.
  ///
  /// In ja, this message translates to:
  /// **'作成後、backend API の生成結果を保存し、共有URLから再表示できます。チーム変更・スコア入力はまだ未実装です。'**
  String get teamSetupAlphaNoticeBody;

  /// Message shown after team setup conditions are created.
  ///
  /// In ja, this message translates to:
  /// **'チーム用セットアップ条件を作成しました'**
  String get teamSetupCreatedMessage;

  /// Title shown on the team match table page.
  ///
  /// In ja, this message translates to:
  /// **'チーム対戦表'**
  String get teamScheduleTitle;

  /// Title shown on the team match table list.
  ///
  /// In ja, this message translates to:
  /// **'チーム対戦表一覧'**
  String get teamScheduleListTitle;

  /// Title shown when the team schedule list is empty.
  ///
  /// In ja, this message translates to:
  /// **'チーム対戦表はまだありません'**
  String get teamScheduleListEmptyTitle;

  /// Message shown when the team schedule list is empty.
  ///
  /// In ja, this message translates to:
  /// **'チーム対戦表を作成または共有URLから開くと、この端末の一覧に表示されます。'**
  String get teamScheduleListEmptyMessage;

  /// Title shown when the team schedule list cannot be loaded.
  ///
  /// In ja, this message translates to:
  /// **'一覧を読み込めませんでした'**
  String get teamScheduleListLoadErrorTitle;

  /// Message shown when the team schedule list cannot be loaded.
  ///
  /// In ja, this message translates to:
  /// **'端末内の保存履歴を確認できませんでした。もう一度お試しください。'**
  String get teamScheduleListLoadErrorMessage;

  /// Fallback title for a team schedule without an event title.
  ///
  /// In ja, this message translates to:
  /// **'タイトル未設定のチーム対戦表'**
  String get teamScheduleUntitledEvent;

  /// Label showing a team schedule share ID.
  ///
  /// In ja, this message translates to:
  /// **'共有ID: {shareId}'**
  String teamScheduleListShareId(String shareId);

  /// Label showing team count in the schedule list.
  ///
  /// In ja, this message translates to:
  /// **'{teamCount}チーム'**
  String teamScheduleListTeamCount(int teamCount);

  /// Label showing member count in the schedule list.
  ///
  /// In ja, this message translates to:
  /// **'{memberCount}人'**
  String teamScheduleListMemberCount(int memberCount);

  /// Label showing when a team schedule was updated.
  ///
  /// In ja, this message translates to:
  /// **'更新: {updatedAt}'**
  String teamScheduleListUpdatedAt(String updatedAt);

  /// Tooltip for opening the team navigation menu.
  ///
  /// In ja, this message translates to:
  /// **'チーム用メニューを開く'**
  String get teamNavigationMenuTooltip;

  /// Title in the team navigation drawer.
  ///
  /// In ja, this message translates to:
  /// **'チーム乱数表'**
  String get teamNavigationTitle;

  /// Subtitle in the team navigation drawer.
  ///
  /// In ja, this message translates to:
  /// **'チーム用メニュー'**
  String get teamNavigationSubtitle;

  /// Navigation label for the team setup page.
  ///
  /// In ja, this message translates to:
  /// **'チームTOP'**
  String get teamNavigationHome;

  /// Navigation label for the team schedule list.
  ///
  /// In ja, this message translates to:
  /// **'対戦表一覧'**
  String get teamNavigationScheduleList;

  /// Navigation label for support.
  ///
  /// In ja, this message translates to:
  /// **'サポート'**
  String get teamNavigationSupport;

  /// Section label for other services.
  ///
  /// In ja, this message translates to:
  /// **'サービス一覧'**
  String get teamNavigationServiceList;

  /// Navigation label for the doubles scheduler.
  ///
  /// In ja, this message translates to:
  /// **'ダブルス乱数表'**
  String get teamNavigationDoublesScheduler;

  /// Default event title for a generated team schedule.
  ///
  /// In ja, this message translates to:
  /// **'チーム練習会'**
  String get defaultTeamScheduleEventTitle;

  /// Dialog title for editing team schedule details.
  ///
  /// In ja, this message translates to:
  /// **'まとめて編集'**
  String get teamScheduleBulkEditTitle;

  /// Button label for editing team schedule details.
  ///
  /// In ja, this message translates to:
  /// **'まとめて編集'**
  String get teamScheduleBulkEditButton;

  /// Input label for the team schedule event title.
  ///
  /// In ja, this message translates to:
  /// **'イベントタイトル'**
  String get teamScheduleEventTitleLabel;

  /// Input label for the team schedule memo.
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get teamScheduleMemoLabel;

  /// Tooltip indicating that a team schedule has a memo.
  ///
  /// In ja, this message translates to:
  /// **'メモあり'**
  String get teamScheduleHasMemoTooltip;

  /// Section title for team names in the bulk edit dialog.
  ///
  /// In ja, this message translates to:
  /// **'チーム名'**
  String get teamScheduleBulkEditTeamsSection;

  /// Section title for member names in the bulk edit dialog.
  ///
  /// In ja, this message translates to:
  /// **'メンバー名'**
  String get teamScheduleBulkEditMembersSection;

  /// Input label for a team display name.
  ///
  /// In ja, this message translates to:
  /// **'チーム{teamSlot}'**
  String teamScheduleTeamNameLabel(int teamSlot);

  /// Default team member display name.
  ///
  /// In ja, this message translates to:
  /// **'参加者{memberNo}'**
  String defaultTeamMemberName(int memberNo);

  /// Default team display name.
  ///
  /// In ja, this message translates to:
  /// **'チーム{teamNo}'**
  String defaultTeamName(int teamNo);

  /// Summary of a team schedule.
  ///
  /// In ja, this message translates to:
  /// **'{teamCount}チーム / {memberCount}人 / {concurrentMatchCount}同時進行'**
  String teamScheduleSummary(
      int teamCount, int memberCount, int concurrentMatchCount);

  /// Notice about saved backend team schedule data.
  ///
  /// In ja, this message translates to:
  /// **'backend API の生成結果を保存して表示しています。表示名はこの画面内で編集できます。'**
  String get teamScheduleBackendDataNotice;

  /// Loading message while creating a team schedule.
  ///
  /// In ja, this message translates to:
  /// **'チーム対戦表を作成・保存中です…'**
  String get creatingTeamScheduleMessage;

  /// Loading message while restoring a team schedule.
  ///
  /// In ja, this message translates to:
  /// **'保存済みのチーム対戦表を読み込み中です…'**
  String get restoringTeamScheduleMessage;

  /// Message shown while saving team schedule display data.
  ///
  /// In ja, this message translates to:
  /// **'表示名を保存中です…'**
  String get savingTeamScheduleDisplayMessage;

  /// Title shown when team schedule generation fails.
  ///
  /// In ja, this message translates to:
  /// **'チーム対戦表の作成に失敗しました'**
  String get teamScheduleGenerateFailedTitle;

  /// Body shown when team schedule generation fails without details.
  ///
  /// In ja, this message translates to:
  /// **'backend API または Firestore 保存の応答を確認してください。'**
  String get teamScheduleGenerateFailedBody;

  /// Body shown when team schedule generation fails with details.
  ///
  /// In ja, this message translates to:
  /// **'backend API または Firestore 保存の応答を確認してください。\n\n{detail}'**
  String teamScheduleGenerateFailedBodyWithDetail(String detail);

  /// Title shown when team schedule restoration fails.
  ///
  /// In ja, this message translates to:
  /// **'チーム対戦表の読み込みに失敗しました'**
  String get teamScheduleRestoreFailedTitle;

  /// Body shown when team schedule restoration fails without details.
  ///
  /// In ja, this message translates to:
  /// **'共有IDまたは保存済みデータを確認してください。'**
  String get teamScheduleRestoreFailedBody;

  /// Body shown when team schedule restoration fails with details.
  ///
  /// In ja, this message translates to:
  /// **'共有IDまたは保存済みデータを確認してください。\n\n{detail}'**
  String teamScheduleRestoreFailedBodyWithDetail(String detail);

  /// Message shown when team schedule display data cannot be saved.
  ///
  /// In ja, this message translates to:
  /// **'表示名の保存に失敗しました: {detail}'**
  String teamScheduleDisplaySaveFailedMessage(String detail);

  /// Button label for retrying team schedule generation.
  ///
  /// In ja, this message translates to:
  /// **'もう一度作成'**
  String get retryTeamScheduleGenerateButton;

  /// Button label for retrying team schedule restoration.
  ///
  /// In ja, this message translates to:
  /// **'もう一度読み込む'**
  String get retryTeamScheduleRestoreButton;

  /// Title for the team schedule share section.
  ///
  /// In ja, this message translates to:
  /// **'共有URL'**
  String get teamScheduleShareTitle;

  /// Description for sharing a team schedule URL.
  ///
  /// In ja, this message translates to:
  /// **'このURLを共有すると、保存済みのチーム対戦表を開き直せます。'**
  String get teamScheduleShareDescription;

  /// Label showing a team schedule share ID.
  ///
  /// In ja, this message translates to:
  /// **'共有ID: {shareId}'**
  String teamScheduleShareIdLabel(String shareId);

  /// Button label for copying the team schedule share URL.
  ///
  /// In ja, this message translates to:
  /// **'共有URLをコピー'**
  String get copyTeamScheduleShareUrlButton;

  /// Message shown after copying the team schedule share URL.
  ///
  /// In ja, this message translates to:
  /// **'共有URLをコピーしました'**
  String get teamScheduleShareUrlCopiedMessage;

  /// Title for the next team match section.
  ///
  /// In ja, this message translates to:
  /// **'次の対戦'**
  String get nextTeamMatchTitle;

  /// Title for a team schedule round.
  ///
  /// In ja, this message translates to:
  /// **'第{roundNo}ラウンド'**
  String teamRoundTitle(int roundNo);

  /// Title for a team schedule court.
  ///
  /// In ja, this message translates to:
  /// **'コート{courtNo}'**
  String teamCourtTitle(int courtNo);

  /// Title combining a court number and match title.
  ///
  /// In ja, this message translates to:
  /// **'コート{courtNo}: {matchTitle}'**
  String teamCourtMatchTitle(int courtNo, String matchTitle);

  /// Title for the team list.
  ///
  /// In ja, this message translates to:
  /// **'チーム一覧'**
  String get teamListTitle;

  /// Label for selecting a team.
  ///
  /// In ja, this message translates to:
  /// **'{teamName} ({memberCount}人)'**
  String teamChoiceLabel(String teamName, int memberCount);

  /// Title for members of the selected team.
  ///
  /// In ja, this message translates to:
  /// **'{teamName} のメンバー'**
  String selectedTeamMembersTitle(String teamName);

  /// Separator between two team names.
  ///
  /// In ja, this message translates to:
  /// **' vs '**
  String get teamMatchVsSeparator;

  /// Separator between multiple team names.
  ///
  /// In ja, this message translates to:
  /// **' / '**
  String get teamMatchGroupSeparator;

  /// Standalone versus label shown between team scores.
  ///
  /// In ja, this message translates to:
  /// **'vs'**
  String get teamMatchVsLabel;

  /// Tooltip for editing the event title.
  ///
  /// In ja, this message translates to:
  /// **'イベントタイトルを編集'**
  String get editTeamScheduleEventTitleTooltip;

  /// Tooltip for editing a team name.
  ///
  /// In ja, this message translates to:
  /// **'チーム名を編集'**
  String get editTeamNameTooltip;

  /// Tooltip for editing a team member display name.
  ///
  /// In ja, this message translates to:
  /// **'メンバー表示名を編集'**
  String get editTeamMemberNameTooltip;

  /// Dialog title for editing the event title.
  ///
  /// In ja, this message translates to:
  /// **'イベントタイトルを編集'**
  String get editTeamScheduleEventTitleDialogTitle;

  /// Dialog title for editing a team name.
  ///
  /// In ja, this message translates to:
  /// **'{teamName} を編集'**
  String editTeamNameDialogTitle(String teamName);

  /// Dialog title for editing a team member name.
  ///
  /// In ja, this message translates to:
  /// **'{memberName} を編集'**
  String editTeamMemberNameDialogTitle(String memberName);

  /// Input label for a display name.
  ///
  /// In ja, this message translates to:
  /// **'表示名'**
  String get displayNameInputLabel;

  /// Title for the team schedule sport and score section.
  ///
  /// In ja, this message translates to:
  /// **'スコア入力'**
  String get teamScheduleSportSectionTitle;

  /// Label for no selected sport.
  ///
  /// In ja, this message translates to:
  /// **'未選択'**
  String get teamScheduleSportNoneLabel;

  /// Label for boccia.
  ///
  /// In ja, this message translates to:
  /// **'ボッチャ'**
  String get teamScheduleSportBocciaLabel;

  /// Help text for selecting a team schedule sport.
  ///
  /// In ja, this message translates to:
  /// **'競技を選択すると、対戦カードからスコアを入力できます。'**
  String get teamScheduleSportHelp;

  /// Message shown while saving team schedule scores.
  ///
  /// In ja, this message translates to:
  /// **'スコアを保存中です…'**
  String get savingTeamScheduleScoresMessage;

  /// Message shown when team schedule scores cannot be saved.
  ///
  /// In ja, this message translates to:
  /// **'スコアの保存に失敗しました: {detail}'**
  String teamScheduleScoresSaveFailedMessage(String detail);

  /// Notice about concurrent team schedule editing.
  ///
  /// In ja, this message translates to:
  /// **'複数端末で同時に編集すると、保存内容が意図どおり反映されない場合があります。'**
  String get teamScheduleConcurrentEditNotice;

  /// Message shown while refreshing team schedule scores.
  ///
  /// In ja, this message translates to:
  /// **'最新のスコア情報を取得しています...'**
  String get refreshingTeamScheduleScoresMessage;

  /// Message shown after refreshing boccia score data.
  ///
  /// In ja, this message translates to:
  /// **'最新の情報に更新しました'**
  String get bocciaScoreRefreshedMessage;

  /// Message shown when boccia score refresh fails.
  ///
  /// In ja, this message translates to:
  /// **'最新の情報を取得できませんでした'**
  String get refreshBocciaScoreFailedMessage;

  /// Dialog title for refreshing while boccia changes are unsaved.
  ///
  /// In ja, this message translates to:
  /// **'未保存の変更を破棄して更新しますか？'**
  String get refreshBocciaScoreDiscardChangesTitle;

  /// Dialog body for refreshing while boccia changes are unsaved.
  ///
  /// In ja, this message translates to:
  /// **'最新の情報に更新すると、保存していない入力内容は破棄されます。'**
  String get refreshBocciaScoreDiscardChangesBody;

  /// Button label for confirming a boccia score refresh.
  ///
  /// In ja, this message translates to:
  /// **'更新する'**
  String get confirmRefreshBocciaScoreButton;

  /// Message shown when score input is opened before selecting a sport.
  ///
  /// In ja, this message translates to:
  /// **'先に競技を選択してください。'**
  String get selectSportBeforeScoreInputMessage;

  /// Message shown for an unsupported boccia match shape.
  ///
  /// In ja, this message translates to:
  /// **'ボッチャのスコア入力は2チーム対戦のみ対応しています。'**
  String get unsupportedBocciaMatchMessage;

  /// Button label for entering a boccia score.
  ///
  /// In ja, this message translates to:
  /// **'スコア入力'**
  String get inputBocciaScoreButton;

  /// Button label for editing a boccia score.
  ///
  /// In ja, this message translates to:
  /// **'スコア編集'**
  String get editBocciaScoreButton;

  /// Summary of a boccia match score.
  ///
  /// In ja, this message translates to:
  /// **'{redTeamName} {redScore} - {blueScore} {blueTeamName}'**
  String bocciaScoreSummary(
      String redTeamName, int redScore, int blueScore, String blueTeamName);

  /// Title for the boccia score dialog.
  ///
  /// In ja, this message translates to:
  /// **'ボッチャ スコア入力'**
  String get bocciaScoreDialogTitle;

  /// Match title shown in the boccia score dialog.
  ///
  /// In ja, this message translates to:
  /// **'{redTeamName} vs {blueTeamName}'**
  String bocciaScoreDialogMatchTitle(String redTeamName, String blueTeamName);

  /// Title for a boccia end throw log.
  ///
  /// In ja, this message translates to:
  /// **'{endNo}E 投球ログ'**
  String bocciaThrowLogTitle(int endNo);

  /// Help text for adding boccia throw logs.
  ///
  /// In ja, this message translates to:
  /// **'投球場所に設定された参加者の＋を押すと、このエンドの投球ログに追加します。'**
  String get bocciaThrowLogHelp;

  /// Summary of red and blue boccia throw counts.
  ///
  /// In ja, this message translates to:
  /// **'投球数：赤：{redCount}　青：{blueCount}'**
  String bocciaThrowCountSummary(int redCount, int blueCount);

  /// Progress toward the maximum boccia throw count.
  ///
  /// In ja, this message translates to:
  /// **'{count} / {maxCount}投'**
  String bocciaThrowCountProgress(int count, int maxCount);

  /// Label for the first boccia team.
  ///
  /// In ja, this message translates to:
  /// **'先攻'**
  String get bocciaFirstTeamLabel;

  /// Label for the second boccia team.
  ///
  /// In ja, this message translates to:
  /// **'後攻'**
  String get bocciaSecondTeamLabel;

  /// Label for the red boccia side.
  ///
  /// In ja, this message translates to:
  /// **'赤'**
  String get bocciaRedSideLabel;

  /// Label for the blue boccia side.
  ///
  /// In ja, this message translates to:
  /// **'青'**
  String get bocciaBlueSideLabel;

  /// Button label for swapping boccia team order.
  ///
  /// In ja, this message translates to:
  /// **'先攻 🔁 後攻'**
  String get swapBocciaOrderButton;

  /// Tooltip for swapping boccia team order and scores.
  ///
  /// In ja, this message translates to:
  /// **'先攻と後攻をスコアごと入れ替える'**
  String get swapBocciaOrderTooltip;

  /// Short label for a boccia end.
  ///
  /// In ja, this message translates to:
  /// **'{endNo} E'**
  String bocciaEndLabel(int endNo);

  /// Button label for editing boccia throwing boxes.
  ///
  /// In ja, this message translates to:
  /// **'投球場所を設定する'**
  String get bocciaThrowingBoxSettingsButton;

  /// Button label for returning to the boccia throw log.
  ///
  /// In ja, this message translates to:
  /// **'投球ログに戻る'**
  String get bocciaReturnToThrowLogButton;

  /// Message shown when boccia throwing boxes can no longer be edited.
  ///
  /// In ja, this message translates to:
  /// **'投球ログ入力後は投球場所を変更できません'**
  String get bocciaThrowingBoxLockedMessage;

  /// Label for an unused boccia throwing box.
  ///
  /// In ja, this message translates to:
  /// **'未使用'**
  String get bocciaUnusedThrowingBoxLabel;

  /// Fallback participant name in the boccia score dialog.
  ///
  /// In ja, this message translates to:
  /// **'参加者{playerSlot}'**
  String bocciaDefaultParticipantName(int playerSlot);

  /// Throw count shown for one boccia throwing box.
  ///
  /// In ja, this message translates to:
  /// **'投球数：{count}'**
  String bocciaThrowCountForBox(int count);

  /// Tooltip for adding a boccia throw log.
  ///
  /// In ja, this message translates to:
  /// **'投球ログを追加'**
  String get bocciaAddThrowLogTooltip;

  /// Title for the boccia throw order section.
  ///
  /// In ja, this message translates to:
  /// **'投球順'**
  String get bocciaThrowOrderTitle;

  /// Message shown when there are no boccia throw logs.
  ///
  /// In ja, this message translates to:
  /// **'まだ投球ログはありません。'**
  String get bocciaNoThrowLogsMessage;

  /// Button label for clearing throw logs for one boccia end.
  ///
  /// In ja, this message translates to:
  /// **'このエンドの履歴をクリア'**
  String get clearBocciaEndThrowLogsButton;

  /// One item in the boccia throw order.
  ///
  /// In ja, this message translates to:
  /// **'{throwNo}. {playerName}（{sideLabel} / Box {boxNo}）'**
  String bocciaThrowOrderItem(
      int throwNo, String playerName, String sideLabel, int boxNo);

  /// Tooltip for removing the last boccia throw log.
  ///
  /// In ja, this message translates to:
  /// **'最後の投球を取り消す'**
  String get removeLastBocciaThrowLogTooltip;

  /// Label for total boccia score.
  ///
  /// In ja, this message translates to:
  /// **'合計'**
  String get bocciaTotalLabel;

  /// Message shown after a boccia score is saved.
  ///
  /// In ja, this message translates to:
  /// **'保存しました'**
  String get bocciaScoreSavedMessage;

  /// Status shown when the boccia score has unsaved changes.
  ///
  /// In ja, this message translates to:
  /// **'未保存の変更があります'**
  String get bocciaScoreUnsavedChangesMessage;

  /// Dialog title for unsaved boccia score changes.
  ///
  /// In ja, this message translates to:
  /// **'未保存の変更があります'**
  String get bocciaScoreDiscardChangesTitle;

  /// Dialog body for unsaved boccia score changes.
  ///
  /// In ja, this message translates to:
  /// **'保存していないスコア変更があります。閉じますか？'**
  String get bocciaScoreDiscardChangesBody;

  /// Dialog title for clearing boccia throw logs for one end.
  ///
  /// In ja, this message translates to:
  /// **'このエンドの投球履歴をクリアしますか？'**
  String get clearBocciaEndThrowLogsDialogTitle;

  /// Dialog body for clearing boccia throw logs for one end.
  ///
  /// In ja, this message translates to:
  /// **'選択中エンドの投球順と投球数を削除します。この操作は元に戻せません。'**
  String get clearBocciaEndThrowLogsDialogBody;

  /// Button label for confirming boccia throw log clearing.
  ///
  /// In ja, this message translates to:
  /// **'クリア'**
  String get confirmClearBocciaEndThrowLogsButton;

  /// Button label for returning to boccia score input.
  ///
  /// In ja, this message translates to:
  /// **'入力に戻る'**
  String get returnToBocciaScoreInputButton;

  /// Button label for discarding boccia score changes.
  ///
  /// In ja, this message translates to:
  /// **'保存せず閉じる'**
  String get discardBocciaScoreChangesButton;

  /// Button label for saving and closing the boccia score dialog.
  ///
  /// In ja, this message translates to:
  /// **'保存して閉じる'**
  String get saveAndCloseBocciaScoreButton;

  /// Title for the doubles match status and final score dialog.
  ///
  /// In ja, this message translates to:
  /// **'試合状態・最終スコア'**
  String get doublesMatchEditTitle;

  /// Label for a doubles match that has not started.
  ///
  /// In ja, this message translates to:
  /// **'試合前'**
  String get doublesMatchStatusScheduledLabel;

  /// Label for a doubles match in progress.
  ///
  /// In ja, this message translates to:
  /// **'試合中'**
  String get doublesMatchStatusInProgressLabel;

  /// Label for a completed doubles match.
  ///
  /// In ja, this message translates to:
  /// **'終了'**
  String get doublesMatchStatusCompletedLabel;

  /// Title for selecting a doubles match score.
  ///
  /// In ja, this message translates to:
  /// **'スコアを選択'**
  String get doublesMatchScorePickerTitle;

  /// Button label for clearing both doubles match scores.
  ///
  /// In ja, this message translates to:
  /// **'スコアを未入力に戻す'**
  String get doublesMatchScoreUnsetLabel;

  /// Label for a doubles match start time.
  ///
  /// In ja, this message translates to:
  /// **'開始時間'**
  String get doublesMatchStartTimeLabel;

  /// Label for a doubles match end time.
  ///
  /// In ja, this message translates to:
  /// **'終了時間'**
  String get doublesMatchEndTimeLabel;

  /// Tooltip for setting a match time to the current time.
  ///
  /// In ja, this message translates to:
  /// **'現在時刻を設定'**
  String get doublesMatchSetCurrentTimeTooltip;

  /// Input label for a doubles match note.
  ///
  /// In ja, this message translates to:
  /// **'試合メモ'**
  String get doublesMatchNoteLabel;

  /// Button label for saving doubles match information.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get doublesMatchSaveButton;

  /// Label for the winning side of a completed doubles match.
  ///
  /// In ja, this message translates to:
  /// **'勝ち'**
  String get doublesMatchWinnerLabel;

  /// Label for the losing side of a completed doubles match.
  ///
  /// In ja, this message translates to:
  /// **'負け'**
  String get doublesMatchLoserLabel;

  /// Label for a drawn doubles match.
  ///
  /// In ja, this message translates to:
  /// **'引き分け'**
  String get doublesMatchDrawLabel;

  /// Message shown after doubles match information is saved.
  ///
  /// In ja, this message translates to:
  /// **'試合情報を保存しました'**
  String get doublesMatchSavedMessage;

  /// Message shown after doubles match information is refreshed.
  ///
  /// In ja, this message translates to:
  /// **'試合情報を更新しました'**
  String get doublesMatchRefreshedMessage;

  /// Message shown when doubles match information has a revision conflict.
  ///
  /// In ja, this message translates to:
  /// **'別の端末で試合情報が更新されています。最新情報を取得してください。'**
  String get doublesMatchConflictMessage;

  /// Validation message shown when only one doubles match score is entered.
  ///
  /// In ja, this message translates to:
  /// **'両側のスコアを入力するか、両方とも未入力にしてください。'**
  String get doublesMatchIncompleteScoreMessage;

  /// Validation message shown when a match end time is earlier than its start time.
  ///
  /// In ja, this message translates to:
  /// **'終了時間は開始時間以降にしてください。'**
  String get doublesMatchTimeOrderErrorMessage;

  /// Message shown when required schedule information is unavailable for match editing.
  ///
  /// In ja, this message translates to:
  /// **'この試合の入力に必要な対戦表情報がありません。'**
  String get doublesMatchUnavailableMessage;

  /// Message shown when the displayed schedule is stale before match editing.
  ///
  /// In ja, this message translates to:
  /// **'対戦表が別の端末で更新されています。最新の対戦表を読み込んでください。'**
  String get doublesMatchScheduleChangedMessage;

  /// Message shown when doubles match information cannot be saved.
  ///
  /// In ja, this message translates to:
  /// **'試合情報を保存できませんでした: {error}'**
  String doublesMatchSaveFailedMessage(String error);

  /// Common application footer with release version.
  ///
  /// In ja, this message translates to:
  /// **'© 2026 S.R.P. · ver.{version}'**
  String appFooterText(String version);

  /// Button label for editing doubles event information.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報を編集'**
  String get editDoublesEventInfoButton;

  /// Dialog title for editing doubles event information.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報を編集'**
  String get editDoublesEventInfoDialogTitle;

  /// Input label for a doubles event title.
  ///
  /// In ja, this message translates to:
  /// **'イベントタイトル'**
  String get doublesEventTitleLabel;

  /// Input label for a doubles event memo.
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get doublesEventMemoLabel;

  /// Validation message for an empty doubles event title.
  ///
  /// In ja, this message translates to:
  /// **'イベントタイトルを入力してください'**
  String get doublesEventTitleRequiredMessage;

  /// Validation message for an empty doubles player display name.
  ///
  /// In ja, this message translates to:
  /// **'プレイヤー表示名を入力してください'**
  String get doublesPlayerDisplayNameRequiredMessage;

  /// Message shown after doubles event information is saved.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報を保存しました'**
  String get doublesEventInfoSavedMessage;

  /// Message shown after a doubles event revision conflict.
  ///
  /// In ja, this message translates to:
  /// **'別の端末でイベント情報が更新されていました。入力内容は保持しています。最新情報を確認して、もう一度保存してください。'**
  String get doublesEventInfoConflictMessage;

  /// Message shown when latest doubles event information cannot be loaded.
  ///
  /// In ja, this message translates to:
  /// **'最新のイベント情報を取得できませんでした。画面を更新してから、もう一度お試しください。'**
  String get doublesEventInfoLatestLoadFailedMessage;

  /// Message shown when doubles event information cannot be saved.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報を保存できませんでした: {error}'**
  String doublesEventInfoSaveFailedMessage(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
