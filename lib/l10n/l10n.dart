import 'app_localizations.dart';

export 'app_localizations.dart';

extension DoublesMatchNavigationLocalizations on AppLocalizations {
  String doublesMatchPositionLabel(int roundNo, int courtNo) {
    return '${teamRoundTitle(roundNo)}$teamMatchGroupSeparator${teamCourtTitle(courtNo)}';
  }

  String doublesProgressPositionLabel(int roundNo, String courtLabel) {
    final courtTitle = teamCourtTitle(0).replaceFirst('0', courtLabel);
    return '${teamRoundTitle(roundNo)}$teamMatchGroupSeparator$courtTitle';
  }

  String get doublesProgressInProgressTitle =>
      doublesMatchStatusInProgressLabel;

  String get doublesProgressNextMatchTitle => nextTeamMatchTitle;

  String get doublesProgressAllCompletedLabel =>
      doublesMatchStatusCompletedLabel;
}

extension TennisBearProfileLinkLocalizations on AppLocalizations {
  bool get _isJapanese => localeName.startsWith('ja');

  String get tennisBearProfileLinkTitlePrefix =>
      _isJapanese ? 'プロフィール連携：' : 'Profile link: ';

  String get tennisBearProfileLinkTitleSource =>
      _isJapanese ? 'テニスベア' : 'TennisBear';

  String get tennisBearProfileLinkSubtitle => _isJapanese
      ? 'テニスベアの公開プロフィールとLanskeアカウントの連携情報は、Lanskeで記録された対戦スコアから、あなたの統計データを集計するために利用します。'
      : 'Your TennisBear public profile link is used to aggregate your statistics from match scores recorded in Lanske.';

  String get myPageProfileLinkTitle =>
      _isJapanese ? 'プロフィール連携' : 'Profile links';

  String get myPageProfileLinkRefreshTooltip =>
      _isJapanese ? '連携状態を更新' : 'Refresh link status';

  String get myPageProfileLinkLoadingMessage =>
      _isJapanese ? 'プロフィール連携の状態を確認しています…' : 'Checking profile link status…';

  String get myPageProfileLinkLoadErrorTitle => _isJapanese
      ? 'プロフィール連携の状態を確認できませんでした'
      : 'Could not check profile link status';

  String get myPageProfileLinkLoadErrorBody => _isJapanese
      ? '通信状態を確認して、もう一度お試しください。連携の管理画面はそのまま開けます。'
      : 'Check your connection and try again. You can still open profile link management.';

  String get myPageProfileLinkManageButton =>
      _isJapanese ? 'プロフィール連携を管理' : 'Manage profile link';

  String get tennisBearProfileLinkRefreshTooltip =>
      _isJapanese ? '最新の状態に更新' : 'Refresh status';

  String get tennisBearProfileLinkLinkedStatus =>
      _isJapanese ? '承認済み' : 'Linked';

  String get tennisBearProfileLinkPendingStatus =>
      _isJapanese ? '申請中' : 'Pending';

  String get tennisBearProfileLinkExpiredStatus =>
      _isJapanese ? '確認コードの期限切れ' : 'Confirmation code expired';

  String get tennisBearProfileLinkNotLinkedStatus =>
      _isJapanese ? '未連携' : 'Not linked';

  String get tennisBearProfileLinkRetryStatus =>
      _isJapanese ? '再申請できます' : 'You can apply again';

  String get tennisBearProfileLinkOpenProfileButton =>
      _isJapanese ? 'テニスベアでプロフィールを開く' : 'Open profile on TennisBear';

  String get tennisBearProfileLinkPermissionNotice => _isJapanese
      ? 'プロフィール連携だけを理由に、イベントや対戦表全体の閲覧権が付与されることはありません。'
      : 'Linking a profile does not grant access to entire events or schedules.';

  String get tennisBearProfileLinkUnlinkButton =>
      _isJapanese ? 'プロフィール連携を解除' : 'Unlink profile';

  String get tennisBearProfileLinkConfirmationCodeLabel =>
      _isJapanese ? '確認コード' : 'Confirmation code';

  String get tennisBearProfileLinkCopyCodeTooltip =>
      _isJapanese ? '確認コードをコピー' : 'Copy confirmation code';

  String get tennisBearProfileLinkCodeNotRestoredMessage => _isJapanese
      ? '確認コードは安全のため保存していません。この画面を再読み込みした場合、同じコードは再表示できません。確認コードが不明の場合は再発行してください。'
      : 'For security, the confirmation code is not stored. After reloading this page, the same code cannot be shown again. Reissue the code if you no longer have it.';

  String get tennisBearProfileLinkExpiredMessage => _isJapanese
      ? '確認コードのシステム上の有効期限（7日間）が過ぎています。再発行すると新しいコードで確認をやり直せます。'
      : 'The seven-day system validity period has expired. Reissue a new code to restart confirmation.';

  String get tennisBearProfileLinkPendingInstruction => _isJapanese
      ? 'テニスベアでLanske管理者のプロフィールを開き、チャットから確認コードを送信してください。'
      : 'Open the Lanske administrator profile on TennisBear and send the confirmation code through chat.';

  String get tennisBearProfileLinkPendingCompletionNotice => _isJapanese
      ? '連携完了後、テニスベアのチャットでお知らせします。'
      : 'We will let you know through TennisBear chat after the link is completed.';

  String get tennisBearProfileLinkOpenAdminProfileButton => _isJapanese
      ? 'Lanske管理者のテニスベアプロフィールを開く'
      : 'Open the Lanske administrator profile on TennisBear';

  String get tennisBearProfileLinkReissueExpiredButton =>
      _isJapanese ? '確認コードを再発行' : 'Reissue confirmation code';

  String get tennisBearProfileLinkReissueButton =>
      _isJapanese ? '新しい確認コードを再発行' : 'Reissue a new confirmation code';

  String get tennisBearProfileLinkCancelRequestButton =>
      _isJapanese ? '申請を取り消す' : 'Cancel request';

  String get tennisBearProfileLinkProfileUrlLabel =>
      _isJapanese ? 'テニスベア公開プロフィールURL' : 'Public TennisBear profile URL';

  String get tennisBearProfileLinkProfileUrlEmptyError =>
      _isJapanese ? 'プロフィールURLを入力してください。' : 'Enter your profile URL.';

  String get tennisBearProfileLinkProfileUrlInvalidError => _isJapanese
      ? 'テニスベアの公開プロフィールURLを入力してください。'
      : 'Enter a valid public TennisBear profile URL.';

  String get tennisBearProfileLinkSubmitButton =>
      _isJapanese ? '確認コードを発行' : 'Issue confirmation code';

  String get tennisBearProfileLinkApplicationStepsTitle =>
      _isJapanese ? '申請手順' : 'How to apply';

  List<String> get tennisBearProfileLinkApplicationSteps => _isJapanese
      ? const [
          'テニスベアのアプリで自分のマイページを開く',
          '右上の共有ボタンをタップ',
          '「外部サービスで共有」をタップ',
          'プロフィールURLをコピー',
          'Lanskeの入力欄に貼り付ける',
          '「確認コードを発行」をタップ',
        ]
      : const [
          'Open your My Page in the TennisBear app',
          'Tap the share button in the top-right corner',
          'Tap “Share with external services”',
          'Copy your profile URL',
          'Paste it into the Lanske input field',
          'Tap “Issue confirmation code”',
        ];

  String get tennisBearProfileLinkRiskTitle =>
      _isJapanese ? '申請前に確認してください' : 'Before you apply';

  String get tennisBearProfileLinkRiskOfficial => _isJapanese
      ? 'テニスベア公式のアカウント連携機能ではなく、Lanske独自のプロフィール連携機能です。'
      : 'This is a Lanske profile-link feature, not an official TennisBear account-link feature.';

  String get tennisBearProfileLinkRiskWrongProfile => _isJapanese
      ? '誤ったプロフィールを連携すると、そのプロフィールに紐づく統計が自分の情報として集計される可能性があります。'
      : 'Linking the wrong profile may cause statistics for that profile to be aggregated as your information.';

  String get tennisBearProfileLinkRiskPermission => _isJapanese
      ? 'プロフィール連携だけでは、イベントや対戦表全体の閲覧権は付与されません。'
      : 'Profile linking alone does not grant access to entire events or schedules.';

  String get tennisBearProfileLinkRiskUnlinkData => _isJapanese
      ? '連携を解除しても、過去のイベント・試合結果などの元データは削除されません。'
      : 'Unlinking does not delete historical event or match-result data.';

  String get tennisBearProfileLinkRetryUnlinked => _isJapanese
      ? '以前のプロフィール連携は解除されています。再連携する場合は、新しい確認コードで改めて申請してください。'
      : 'The previous profile link was removed. To link again, submit a new request with a new confirmation code.';

  String get tennisBearProfileLinkRetryRejected => _isJapanese
      ? '以前の申請は承認されませんでした。内容を確認して改めて申請できます。'
      : 'The previous request was not approved. Review the details and apply again.';

  String get tennisBearProfileLinkRetryCanceled => _isJapanese
      ? '以前の申請は取り消されています。改めて申請できます。'
      : 'The previous request was canceled. You can apply again.';

  String get tennisBearProfileLinkRetryExpired => _isJapanese
      ? '以前の申請は期限切れです。改めて申請できます。'
      : 'The previous request expired. You can apply again.';

  String get tennisBearProfileLinkCreateSuccess => _isJapanese
      ? '確認コードを発行しました。テニスベアでLanske管理者のプロフィールを開き、チャットから確認コードを送信してください。'
      : 'Confirmation code issued. Open the Lanske administrator profile on TennisBear and send the confirmation code through chat.';

  String get tennisBearProfileLinkReissueDialogTitle =>
      _isJapanese ? '確認コードを再発行しますか？' : 'Reissue the confirmation code?';

  String get tennisBearProfileLinkReissueDialogBody => _isJapanese
      ? '現在の確認コードは無効になります。新しいコードを発行したあと、テニスベアでLanske管理者のプロフィールを開き、チャットから送信してください。'
      : 'The current confirmation code will become invalid. After a new code is issued, open the Lanske administrator profile on TennisBear and send it through chat.';

  String get tennisBearProfileLinkReissueDialogAction =>
      _isJapanese ? '再発行する' : 'Reissue';

  String get tennisBearProfileLinkReissueSuccess => _isJapanese
      ? '新しい確認コードを発行しました。旧コードは無効です。'
      : 'A new confirmation code was issued. The old code is invalid.';

  String get tennisBearProfileLinkCancelDialogTitle =>
      _isJapanese ? '申請を取り消しますか？' : 'Cancel this request?';

  String get tennisBearProfileLinkCancelDialogBody => _isJapanese
      ? '現在の連携申請と確認コードを無効にします。必要になった場合は、プロフィールURLの入力から改めて申請できます。'
      : 'This invalidates the current link request and confirmation code. You can apply again later from the profile URL input.';

  String get tennisBearProfileLinkCancelDialogAction =>
      _isJapanese ? '申請を取り消す' : 'Cancel request';

  String get tennisBearProfileLinkCancelSuccess =>
      _isJapanese ? '連携申請を取り消しました。' : 'The link request was canceled.';

  String get tennisBearProfileLinkUnlinkDialogTitle =>
      _isJapanese ? 'テニスベアプロフィール連携を解除しますか？' : 'Unlink the TennisBear profile?';

  String get tennisBearProfileLinkUnlinkDialogBody => _isJapanese
      ? '連携を解除しても、過去のイベント・参加者・試合結果などの元データは削除されません。再連携する場合は、新しい確認コードによる確認が必要です。'
      : 'Unlinking does not delete historical event, participant, or match-result data. Linking again requires confirmation with a new code.';

  String get tennisBearProfileLinkUnlinkDialogAction =>
      _isJapanese ? '連携を解除する' : 'Unlink';

  String get tennisBearProfileLinkUnlinkSuccess => _isJapanese
      ? 'テニスベアプロフィール連携を解除しました。必要な場合は改めて申請できます。'
      : 'The TennisBear profile was unlinked. You can apply again if needed.';

  String tennisBearProfileLinkClipboardText(String code) => _isJapanese
      ? 'Lanske-テニスベアプロフィール連携確認コード\n$code'
      : 'Lanske-TennisBear profile link confirmation code\n$code';

  String get tennisBearProfileLinkCodeCopied => _isJapanese
      ? 'テニスベアチャット送信用の確認コードをコピーしました。'
      : 'Copied the confirmation code for TennisBear chat.';

  String get tennisBearProfileLinkInvalidUrlMessage => _isJapanese
      ? 'テニスベアの公開プロフィールURLの形式を確認してください。'
      : 'Check the public TennisBear profile URL format.';

  String get tennisBearProfileLinkUserNotFoundMessage => _isJapanese
      ? 'Lanskeアカウント情報を確認できませんでした。アカウント情報を再確認してからお試しください。'
      : 'Lanske account information could not be confirmed. Recheck the account information and try again.';

  String get tennisBearProfileLinkRequestUpdatedMessage => _isJapanese
      ? '申請状態が更新されています。最新の状態を確認してください。'
      : 'The request state has changed. Refresh the latest state.';

  String get tennisBearProfileLinkRequestChangedMessage => _isJapanese
      ? '申請状態が変更されています。最新の状態を確認してからもう一度お試しください。'
      : 'The request state changed. Refresh the latest state and try again.';

  String get tennisBearProfileLinkCodeExpiredMessage => _isJapanese
      ? '確認コードの有効期限が切れています。新しいコードを再発行してください。'
      : 'The confirmation code has expired. Reissue a new code.';

  String get tennisBearProfileLinkGenericConflictMessage => _isJapanese
      ? 'このテニスベアプロフィールとは連携できません。不明点がある場合はお問い合わせください。'
      : 'This TennisBear profile cannot be linked. Please contact us if you need help.';

  String get tennisBearProfileLinkGenericFailureMessage => _isJapanese
      ? 'プロフィール連携の処理に失敗しました。通信状態を確認して、もう一度お試しください。'
      : 'Profile linking failed. Check your connection and try again.';
}
