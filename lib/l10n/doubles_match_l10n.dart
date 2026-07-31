import 'app_localizations.dart';

extension DoublesMatchLocalizations on AppLocalizations {
  bool get _isJapanese => localeName.startsWith('ja');

  String get doublesMatchEditTitle =>
      _isJapanese ? '試合状態・最終スコア' : 'Match status and final score';

  String get doublesMatchStatusScheduledLabel =>
      _isJapanese ? '試合前' : 'Scheduled';

  String get doublesMatchStatusInProgressLabel =>
      _isJapanese ? '試合中' : 'In progress';

  String get doublesMatchStatusCompletedLabel =>
      _isJapanese ? '終了' : 'Completed';

  String get doublesMatchScorePickerTitle =>
      _isJapanese ? 'スコアを選択' : 'Select score';

  String get doublesMatchScoreUnsetLabel =>
      _isJapanese ? 'スコアを未入力に戻す' : 'Clear score';

  String get doublesMatchStartTimeLabel =>
      _isJapanese ? '開始時間' : 'Start time';

  String get doublesMatchEndTimeLabel =>
      _isJapanese ? '終了時間' : 'End time';

  String get doublesMatchSetCurrentTimeTooltip =>
      _isJapanese ? '現在時刻を設定' : 'Set current time';

  String get doublesMatchNoteLabel => _isJapanese ? '試合メモ' : 'Match note';

  String get doublesMatchSaveButton => _isJapanese ? '保存' : 'Save';

  String get doublesMatchWinnerLabel => _isJapanese ? '勝ち' : 'Winner';

  String get doublesMatchLoserLabel => _isJapanese ? '負け' : 'Loser';

  String get doublesMatchDrawLabel => _isJapanese ? '引き分け' : 'Draw';

  String get doublesMatchSavedMessage =>
      _isJapanese ? '試合情報を保存しました' : 'Match information saved';

  String get doublesMatchRefreshedMessage =>
      _isJapanese ? '試合情報を更新しました' : 'Match information refreshed';

  String get doublesMatchConflictMessage => _isJapanese
      ? '別の端末で試合情報が更新されています。最新情報を取得してください。'
      : 'This match was updated on another device. Refresh the latest information.';

  String get doublesMatchIncompleteScoreMessage => _isJapanese
      ? '両側のスコアを入力するか、両方とも未入力にしてください。'
      : 'Enter both scores or leave both scores unset.';

  String get doublesMatchTimeOrderErrorMessage => _isJapanese
      ? '終了時間は開始時間以降にしてください。'
      : 'End time must not be earlier than start time.';

  String get doublesMatchUnavailableMessage => _isJapanese
      ? 'この試合の入力に必要な対戦表情報がありません。'
      : 'Schedule information required to edit this match is unavailable.';

  String get doublesMatchScheduleChangedMessage => _isJapanese
      ? '対戦表が別の端末で更新されています。最新の対戦表を読み込んでください。'
      : 'The schedule was updated on another device. Reload the latest schedule.';

  String doublesMatchSaveFailedMessage(String error) => _isJapanese
      ? '試合情報を保存できませんでした: $error'
      : 'Could not save match information: $error';
}
