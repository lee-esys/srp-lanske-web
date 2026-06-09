import 'app_localizations.dart';

extension TeamL10n on AppLocalizations {
  bool get _isJapanese => localeName.startsWith('ja');

  String get teamSetupMenuTitle => _isJapanese ? 'らんすけ：チーム' : 'Lanske: Team';

  String get teamSetupMenuSubtitle => _isJapanese
      ? 'チーム用対戦表を作成'
      : 'Create a team match table';

  String get teamSetupTitle => _isJapanese ? 'らんすけ：チーム' : 'Lanske: Team';

  String get teamSetupInstruction => _isJapanese
      ? 'チーム数・人数などを指定して、チーム用対戦表を作成します。'
      : 'Set team and participant counts to create a team match table.';

  String get teamSetupSupportedConditions => _isJapanese
      ? '初期MVPでは、1〜2コート / 10チーム程度までを主な確認範囲としています。'
      : 'For the initial MVP, the main verification range is 1 to 2 courts and roughly up to 10 teams.';

  String get teamSetupInputUpperLimitNote => _isJapanese
      ? '入力上限: コート数5 / チーム数25 / 参加人数50 / チーム人数25 / 1ラウンドに出るチーム数25'
      : 'Input limits: 5 courts / 25 teams / 50 participants / 25 members per team / 25 active teams per round';

  String get teamCountLabel => _isJapanese ? 'チーム数' : 'Teams';

  String get activeTeamCountPerRoundLabel => _isJapanese
      ? '1ラウンドに出るチーム数'
      : 'Active teams per round';

  String get teamSizeLabel => _isJapanese ? 'チーム人数' : 'Members per team';

  String get participantCountLabel => _isJapanese ? '参加人数' : 'Participants';

  String get decrementTeamCountTooltip => _isJapanese
      ? 'チーム数を減らす'
      : 'Decrease team count';

  String get incrementTeamCountTooltip => _isJapanese
      ? 'チーム数を増やす'
      : 'Increase team count';

  String get decrementActiveTeamCountPerRoundTooltip => _isJapanese
      ? '1ラウンドに出るチーム数を減らす'
      : 'Decrease active teams per round';

  String get incrementActiveTeamCountPerRoundTooltip => _isJapanese
      ? '1ラウンドに出るチーム数を増やす'
      : 'Increase active teams per round';

  String get decrementTeamSizeTooltip => _isJapanese
      ? 'チーム人数を減らす'
      : 'Decrease members per team';

  String get incrementTeamSizeTooltip => _isJapanese
      ? 'チーム人数を増やす'
      : 'Increase members per team';

  String get decrementParticipantCountTooltip => _isJapanese
      ? '参加人数を減らす'
      : 'Decrease participant count';

  String get incrementParticipantCountTooltip => _isJapanese
      ? '参加人数を増やす'
      : 'Increase participant count';

  String teamSetupRangeHelp(int minValue, int maxValue) {
    return _isJapanese
        ? '$minValue〜$maxValue の範囲で選択できます。'
        : 'Select a value from $minValue to $maxValue.';
  }

  String get teamSetupDerivedTeamSizeHelp => _isJapanese
      ? 'チーム人数は目安です。余りがある場合は、一部チームが+1人になります。'
      : 'Members per team is a guide. If the participants do not divide evenly, some teams will have one extra member.';

  String get resetTeamSetupButton => _isJapanese ? '入力項目のリセット' : 'Reset inputs';

  String get generateTeamScheduleButton => _isJapanese
      ? 'チーム対戦表を作成'
      : 'Create team match table';

  String get teamSetupMockNoticeTitle => _isJapanese
      ? 'モック確認中'
      : 'Mock flow';

  String get teamSetupMockNoticeBody => _isJapanese
      ? 'backend API 接続前のため、次の作業でチーム用対戦表画面へ接続します。'
      : 'The backend API is not connected yet. The next work item will connect this to the team match table screen.';

  String get teamSetupCreatedMessage => _isJapanese
      ? 'チーム用セットアップ条件を作成しました'
      : 'Team setup conditions were created.';
}
