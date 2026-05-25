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

  /// Title shown on the event setup page.
  ///
  /// In ja, this message translates to:
  /// **'ダブルス乱数表 ver0.1'**
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
  /// **'対戦表が更新されています。最新の情報に更新します'**
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
