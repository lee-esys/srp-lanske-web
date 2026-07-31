import 'dart:convert';
import 'dart:io';

void main() {
  _updateArb(
    path: 'lib/l10n/app_ja.arb',
    serviceTitle: 'らんすけ：ダブルス乱数表',
    values: <String, String>{
      'appFooterText': '© 2026 S.R.P. · ver.{version}',
      'editDoublesEventInfoButton': 'イベント情報を編集',
      'editDoublesEventInfoDialogTitle': 'イベント情報を編集',
      'doublesEventTitleLabel': 'イベントタイトル',
      'doublesEventMemoLabel': 'メモ',
      'doublesEventTitleRequiredMessage': 'イベントタイトルを入力してください',
      'doublesPlayerDisplayNameRequiredMessage': 'プレイヤー表示名を入力してください',
      'doublesEventInfoSavedMessage': 'イベント情報を保存しました',
      'doublesEventInfoConflictMessage':
          '別の端末でイベント情報が更新されていました。入力内容は保持しています。最新情報を確認して、もう一度保存してください。',
      'doublesEventInfoLatestLoadFailedMessage':
          '最新のイベント情報を取得できませんでした。画面を更新してから、もう一度お試しください。',
      'doublesEventInfoSaveFailedMessage': 'イベント情報を保存できませんでした: {error}',
    },
  );
  _updateArb(
    path: 'lib/l10n/app_en.arb',
    serviceTitle: 'Lanske: Doubles Scheduler',
    values: <String, String>{
      'appFooterText': '© 2026 S.R.P. · ver.{version}',
      'editDoublesEventInfoButton': 'Edit event information',
      'editDoublesEventInfoDialogTitle': 'Edit event information',
      'doublesEventTitleLabel': 'Event title',
      'doublesEventMemoLabel': 'Memo',
      'doublesEventTitleRequiredMessage': 'Enter an event title.',
      'doublesPlayerDisplayNameRequiredMessage':
          'Enter a player display name.',
      'doublesEventInfoSavedMessage': 'Event information saved.',
      'doublesEventInfoConflictMessage':
          'Event information was updated on another device. Your input has been kept. Review the latest information and save again.',
      'doublesEventInfoLatestLoadFailedMessage':
          'Could not load the latest event information. Refresh the page and try again.',
      'doublesEventInfoSaveFailedMessage':
          'Could not save event information: {error}',
    },
  );

  _updateDartFile(
    path: 'lib/features/doubles_scheduler/presentation/schedule_page.dart',
    replacements: <_Replacement>[
      const _Replacement(
        "  String get _pageTitle {\n"
            "    return _savedEvent?.event.title ?? widget.draft.eventName;\n"
            "  }\n\n",
        '',
      ),
      const _Replacement(
        "        ScheduleEventSummaryCard(\n"
            "          onShareUrl: _savedEvent == null ? null : _showShareDialog,\n"
            "          onRefresh: () => _reloadSchedule(),",
        "        ScheduleEventSummaryCard(\n"
            "          aggregate: _savedEvent,\n"
            "          onShareUrl: _savedEvent == null ? null : _showShareDialog,\n"
            "          onRefresh: () => _reloadSchedule(),\n"
            "          onRefreshForEdit: () =>\n"
            "              _refreshLatestAll(showSuccess: false),",
      ),
      const _Replacement(
        '        title: Text(_pageTitle),',
        '        title: Text(l10n.eventSetupTitle),',
      ),
    ],
  );

  _updateDartFile(
    path:
        'lib/features/doubles_scheduler/presentation/restored_schedule_page.dart',
    replacements: <_Replacement>[
      const _Replacement(
        "  String _pageTitle(AppLocalizations l10n) {\n"
            "    return _savedEvent?.event.title ?? l10n.matchTableTitle;\n"
            "  }\n\n",
        '',
      ),
      const _Replacement(
        "          ScheduleEventSummaryCard(\n"
            "            onShareUrl: _showShareDialog,\n"
            "            onRefresh: () => _reloadSchedule(),",
        "          ScheduleEventSummaryCard(\n"
            "            aggregate: savedEvent,\n"
            "            onShareUrl: _showShareDialog,\n"
            "            onRefresh: () => _reloadSchedule(),\n"
            "            onRefreshForEdit: () =>\n"
            "                _refreshLatestAll(showSuccess: false),",
      ),
      const _Replacement(
        "        title: Text(\n"
            "          _pageTitle(l10n),\n"
            "          overflow: TextOverflow.ellipsis,\n"
            "        ),",
        '        title: Text(l10n.eventSetupTitle),',
      ),
    ],
  );

  final self = File.fromUri(Platform.script);
  if (self.existsSync()) {
    self.deleteSync();
  }

  stdout.writeln('Issue #137 source updates applied.');
}

void _updateArb({
  required String path,
  required String serviceTitle,
  required Map<String, String> values,
}) {
  final file = File(path);
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  json['eventSetupTitle'] = serviceTitle;
  json['@eventSetupTitle'] = <String, dynamic>{
    'description': 'Title shown on doubles scheduler pages.',
  };

  for (final entry in values.entries) {
    json[entry.key] = entry.value;
    json['@${entry.key}'] = _metadataFor(entry.key);
  }

  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(json)}\n');
}

Map<String, dynamic> _metadataFor(String key) {
  switch (key) {
    case 'appFooterText':
      return <String, dynamic>{
        'description': 'Common application footer with release version.',
        'placeholders': <String, dynamic>{
          'version': <String, dynamic>{
            'type': 'String',
            'example': '0.1.5',
          },
        },
      };
    case 'doublesEventInfoSaveFailedMessage':
      return <String, dynamic>{
        'description':
            'Message shown when doubles event information cannot be saved.',
        'placeholders': <String, dynamic>{
          'error': <String, dynamic>{
            'type': 'String',
            'example': 'network error',
          },
        },
      };
    default:
      return <String, dynamic>{
        'description': _descriptionFor(key),
      };
  }
}

String _descriptionFor(String key) {
  return switch (key) {
    'editDoublesEventInfoButton' =>
      'Button label for editing doubles event information.',
    'editDoublesEventInfoDialogTitle' =>
      'Dialog title for editing doubles event information.',
    'doublesEventTitleLabel' =>
      'Input label for a doubles event title.',
    'doublesEventMemoLabel' => 'Input label for a doubles event memo.',
    'doublesEventTitleRequiredMessage' =>
      'Validation message for an empty doubles event title.',
    'doublesPlayerDisplayNameRequiredMessage' =>
      'Validation message for an empty doubles player display name.',
    'doublesEventInfoSavedMessage' =>
      'Message shown after doubles event information is saved.',
    'doublesEventInfoConflictMessage' =>
      'Message shown after a doubles event revision conflict.',
    'doublesEventInfoLatestLoadFailedMessage' =>
      'Message shown when latest doubles event information cannot be loaded.',
    _ => key,
  };
}

void _updateDartFile({
  required String path,
  required List<_Replacement> replacements,
}) {
  final file = File(path);
  var content = file.readAsStringSync();

  for (final replacement in replacements) {
    if (!content.contains(replacement.before)) {
      throw StateError('Expected source was not found in $path:\n'
          '${replacement.before}');
    }
    content = content.replaceFirst(replacement.before, replacement.after);
  }

  file.writeAsStringSync(content);
}

class _Replacement {
  const _Replacement(this.before, this.after);

  final String before;
  final String after;
}
