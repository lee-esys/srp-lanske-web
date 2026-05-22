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
