import 'app_localizations.dart';

extension TeamL10n on AppLocalizations {
  bool get _isJapanese => localeName.startsWith('ja');

  String get teamSetupMenuTitle => _isJapanese ? 'らんすけ：チーム' : 'Lanske: Team';

  String get teamSetupMenuSubtitle => _isJapanese
      ? 'チーム用対戦表を作成'
      : 'Create a team match table';

  String get teamSetupTitle => _isJapanese ? 'らんすけ：チーム' : 'Lanske: Team';

  String get teamSetupInstruction => _isJapanese
      ? '同時進行試合数・参加人数・チーム数を決めて、チーム用対戦表を作成します。'
      : 'Set simultaneous matches, participants, and teams to create a team match table.';

  String get teamSetupSupportedConditions => _isJapanese
      ? '初期MVPでは、同時進行1〜2試合 / 10チーム程度までを主な確認範囲としています。'
      : 'For the initial MVP, the main verification range is 1 to 2 simultaneous matches and roughly up to 10 teams.';

  String get teamSetupInputUpperLimitNote => _isJapanese
      ? '入力上限: 同時進行試合数5 / 参加人数50 / チーム数25 / 1試合で対戦するチーム数25'
      : 'Input limits: 5 simultaneous matches / 50 participants / 25 teams / 25 teams per match';

  String get concurrentMatchCountLabel => _isJapanese
      ? '同時進行試合数'
      : 'Simultaneous matches';

  String get participantCountLabel => _isJapanese ? '参加人数' : 'Participants';

  String get teamCountLabel => _isJapanese ? 'チーム数' : 'Teams';

  String get teamsPerMatchLabel => _isJapanese
      ? '1試合で対戦するチーム数'
      : 'Teams per match';

  String get decrementConcurrentMatchCountTooltip => _isJapanese
      ? '同時進行試合数を減らす'
      : 'Decrease simultaneous match count';

  String get incrementConcurrentMatchCountTooltip => _isJapanese
      ? '同時進行試合数を増やす'
      : 'Increase simultaneous match count';

  String get decrementParticipantCountTooltip => _isJapanese
      ? '参加人数を減らす'
      : 'Decrease participant count';

  String get incrementParticipantCountTooltip => _isJapanese
      ? '参加人数を増やす'
      : 'Increase participant count';

  String get decrementTeamCountTooltip => _isJapanese
      ? 'チーム数を減らす'
      : 'Decrease team count';

  String get incrementTeamCountTooltip => _isJapanese
      ? 'チーム数を増やす'
      : 'Increase team count';

  String get decrementTeamsPerMatchTooltip => _isJapanese
      ? '1試合で対戦するチーム数を減らす'
      : 'Decrease teams per match';

  String get incrementTeamsPerMatchTooltip => _isJapanese
      ? '1試合で対戦するチーム数を増やす'
      : 'Increase teams per match';

  String teamSetupRangeHelp(int minValue, int maxValue) {
    return _isJapanese
        ? '$minValue〜$maxValue の範囲で選択できます。'
        : 'Select a value from $minValue to $maxValue.';
  }

  String teamMemberCountSummary(int minMemberCount, int maxMemberCount) {
    if (minMemberCount == maxMemberCount) {
      return _isJapanese
          ? '1チーム$minMemberCount人'
          : '$minMemberCount per team';
    }

    return _isJapanese
        ? '1チーム$minMemberCount〜$maxMemberCount人'
        : '$minMemberCount to $maxMemberCount per team';
  }

  String get teamMemberCountSummaryHelp => _isJapanese
      ? '参加人数とチーム数から自動計算します。余りがある場合は、一部チームが+1人になります。'
      : 'Calculated from participants and teams. If the participants do not divide evenly, some teams will have one extra member.';

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
