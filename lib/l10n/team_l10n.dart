import 'app_localizations.dart';

extension TeamL10n on AppLocalizations {
  bool get _isJapanese => localeName.startsWith('ja');

  String get teamSetupMenuTitle => _isJapanese ? 'らんすけ：チーム' : 'Lanske: Team';

  String get teamSetupMenuSubtitle =>
      _isJapanese ? 'チーム用対戦表を作成' : 'Create a team match table';

  String get teamSetupTitle => _isJapanese ? 'らんすけ：チーム' : 'Lanske: Team';

  String get teamSetupInstruction => _isJapanese
      ? '同時進行試合数・参加人数・1チームの目安人数を決めて、チーム用対戦表を作成します。'
      : 'Set simultaneous matches, participants, and preferred team size to create a team match table.';

  String get teamSetupSupportedConditions => _isJapanese
      ? '初期MVPでは、同時進行1〜2試合 / 10チーム程度までを主な確認範囲としています。'
      : 'For the initial MVP, the main verification range is 1 to 2 simultaneous matches and roughly up to 10 teams.';

  String get teamSetupInputUpperLimitNote => _isJapanese
      ? '入力上限: 同時進行試合数5 / 参加人数50 / 1チームの目安人数25 / 1試合で対戦するチーム数25'
      : 'Input limits: 5 simultaneous matches / 50 participants / preferred team size 25 / 25 teams per match';

  String get concurrentMatchCountLabel =>
      _isJapanese ? '同時進行試合数' : 'Simultaneous matches';

  String get participantCountLabel => _isJapanese ? '参加人数' : 'Participants';

  String get preferredTeamSizeLabel =>
      _isJapanese ? '1チームの目安人数' : 'Preferred team size';

  String get teamsPerMatchLabel =>
      _isJapanese ? '1試合で対戦するチーム数' : 'Teams per match';

  String get decrementConcurrentMatchCountTooltip =>
      _isJapanese ? '同時進行試合数を減らす' : 'Decrease simultaneous match count';

  String get incrementConcurrentMatchCountTooltip =>
      _isJapanese ? '同時進行試合数を増やす' : 'Increase simultaneous match count';

  String get decrementParticipantCountTooltip =>
      _isJapanese ? '参加人数を減らす' : 'Decrease participant count';

  String get incrementParticipantCountTooltip =>
      _isJapanese ? '参加人数を増やす' : 'Increase participant count';

  String get decrementPreferredTeamSizeTooltip =>
      _isJapanese ? '1チームの目安人数を減らす' : 'Decrease preferred team size';

  String get incrementPreferredTeamSizeTooltip =>
      _isJapanese ? '1チームの目安人数を増やす' : 'Increase preferred team size';

  String get decrementTeamsPerMatchTooltip =>
      _isJapanese ? '1試合で対戦するチーム数を減らす' : 'Decrease teams per match';

  String get incrementTeamsPerMatchTooltip =>
      _isJapanese ? '1試合で対戦するチーム数を増やす' : 'Increase teams per match';

  String teamSetupRangeHelp(int minValue, int maxValue) {
    return _isJapanese
        ? '$minValue〜$maxValue の範囲で選択できます。'
        : 'Select a value from $minValue to $maxValue.';
  }

  String teamCountSummary(int teamCount) {
    return _isJapanese ? '$teamCountチーム' : '$teamCount teams';
  }

  String get teamCountSummaryHelp => _isJapanese
      ? '参加人数と1チームの目安人数から自動計算します。'
      : 'Calculated automatically from participants and preferred team size.';

  String teamDistributionSummary(String summary) {
    return _isJapanese ? '内訳: $summary' : 'Distribution: $summary';
  }

  String get teamDistributionSummaryHelp => _isJapanese
      ? '余りがある場合は、一部チームの人数が1人少なくなります。'
      : 'If there is a remainder, some teams will have one fewer member.';

  String get teamParticipantInputTitle =>
      _isJapanese ? '参加者名の取り込み' : 'Participant names';

  String get teamParticipantInputDescription => _isJapanese
      ? '改行区切りで参加者名を貼り付けて反映できます。カンマ・読点・タブ区切りも簡易対応します。'
      : 'Paste participant names separated by new lines. Commas and tabs are also supported in a simple form.';

  String get teamParticipantInputLabel =>
      _isJapanese ? '参加者名' : 'Participant names';

  String get teamParticipantInputHint =>
      _isJapanese ? '例:\n田中\n佐藤\n鈴木' : 'Example:\nAlex\nBlair\nCasey';

  String get applyParticipantNamesButton =>
      _isJapanese ? '参加者名を反映' : 'Apply participant names';

  String participantNameCountStatus(int nameCount, int participantCount) {
    return _isJapanese
        ? '入力済み: $nameCount人 / 参加人数: $participantCount人'
        : 'Names: $nameCount / Participants: $participantCount';
  }

  String participantNamesAppliedMessage(int nameCount) {
    return _isJapanese
        ? '$nameCount人の参加者名を反映しました'
        : 'Applied $nameCount participant names.';
  }

  String participantNamesTrimmedMessage(int maxCount) {
    return _isJapanese
        ? '$maxCount人まで取り込みました。超過分は省略しました。'
        : 'Applied up to $maxCount participant names. Extra names were omitted.';
  }

  String get participantNamesTooFewMessage => _isJapanese
      ? '参加者名は2人以上入力してください。'
      : 'Enter at least two participant names.';

  String get participantNamesEmptyMessage =>
      _isJapanese ? '参加者名を入力してください。' : 'Enter participant names.';

  String get resetTeamSetupButton => _isJapanese ? '入力項目のリセット' : 'Reset inputs';

  String get generateTeamScheduleButton =>
      _isJapanese ? 'チーム対戦表を作成' : 'Create team match table';

  String get teamSetupMockNoticeTitle => _isJapanese ? 'モック確認中' : 'Mock flow';

  String get teamSetupMockNoticeBody => _isJapanese
      ? 'backend API 接続前のため、次の作業でチーム用対戦表画面へ接続します。'
      : 'The backend API is not connected yet. The next work item will connect this to the team match table screen.';

  String get teamSetupCreatedMessage => _isJapanese
      ? 'チーム用セットアップ条件を作成しました'
      : 'Team setup conditions were created.';
}
