import 'dart:io';

final Directory root = File.fromUri(Platform.script).parent.parent;
final Directory l10nDirectory = Directory('${root.path}/lib/l10n');

const String jaMessages = r'''  "doublesMatchEditTitle": "試合状態・最終スコア",
  "@doublesMatchEditTitle": {
    "description": "Title for the doubles match status and final score dialog."
  },
  "doublesMatchStatusScheduledLabel": "試合前",
  "@doublesMatchStatusScheduledLabel": {
    "description": "Label for a doubles match that has not started."
  },
  "doublesMatchStatusInProgressLabel": "試合中",
  "@doublesMatchStatusInProgressLabel": {
    "description": "Label for a doubles match in progress."
  },
  "doublesMatchStatusCompletedLabel": "終了",
  "@doublesMatchStatusCompletedLabel": {
    "description": "Label for a completed doubles match."
  },
  "doublesMatchScorePickerTitle": "スコアを選択",
  "@doublesMatchScorePickerTitle": {
    "description": "Title for selecting a doubles match score."
  },
  "doublesMatchScoreUnsetLabel": "スコアを未入力に戻す",
  "@doublesMatchScoreUnsetLabel": {
    "description": "Button label for clearing both doubles match scores."
  },
  "doublesMatchStartTimeLabel": "開始時間",
  "@doublesMatchStartTimeLabel": {
    "description": "Label for a doubles match start time."
  },
  "doublesMatchEndTimeLabel": "終了時間",
  "@doublesMatchEndTimeLabel": {
    "description": "Label for a doubles match end time."
  },
  "doublesMatchSetCurrentTimeTooltip": "現在時刻を設定",
  "@doublesMatchSetCurrentTimeTooltip": {
    "description": "Tooltip for setting a match time to the current time."
  },
  "doublesMatchNoteLabel": "試合メモ",
  "@doublesMatchNoteLabel": {
    "description": "Input label for a doubles match note."
  },
  "doublesMatchSaveButton": "保存",
  "@doublesMatchSaveButton": {
    "description": "Button label for saving doubles match information."
  },
  "doublesMatchWinnerLabel": "勝ち",
  "@doublesMatchWinnerLabel": {
    "description": "Label for the winning side of a completed doubles match."
  },
  "doublesMatchLoserLabel": "負け",
  "@doublesMatchLoserLabel": {
    "description": "Label for the losing side of a completed doubles match."
  },
  "doublesMatchDrawLabel": "引き分け",
  "@doublesMatchDrawLabel": {
    "description": "Label for a drawn doubles match."
  },
  "doublesMatchSavedMessage": "試合情報を保存しました",
  "@doublesMatchSavedMessage": {
    "description": "Message shown after doubles match information is saved."
  },
  "doublesMatchRefreshedMessage": "試合情報を更新しました",
  "@doublesMatchRefreshedMessage": {
    "description": "Message shown after doubles match information is refreshed."
  },
  "doublesMatchConflictMessage": "別の端末で試合情報が更新されています。最新情報を取得してください。",
  "@doublesMatchConflictMessage": {
    "description": "Message shown when doubles match information has a revision conflict."
  },
  "doublesMatchIncompleteScoreMessage": "両側のスコアを入力するか、両方とも未入力にしてください。",
  "@doublesMatchIncompleteScoreMessage": {
    "description": "Validation message shown when only one doubles match score is entered."
  },
  "doublesMatchTimeOrderErrorMessage": "終了時間は開始時間以降にしてください。",
  "@doublesMatchTimeOrderErrorMessage": {
    "description": "Validation message shown when a match end time is earlier than its start time."
  },
  "doublesMatchUnavailableMessage": "この試合の入力に必要な対戦表情報がありません。",
  "@doublesMatchUnavailableMessage": {
    "description": "Message shown when required schedule information is unavailable for match editing."
  },
  "doublesMatchScheduleChangedMessage": "対戦表が別の端末で更新されています。最新の対戦表を読み込んでください。",
  "@doublesMatchScheduleChangedMessage": {
    "description": "Message shown when the displayed schedule is stale before match editing."
  },
  "doublesMatchSaveFailedMessage": "試合情報を保存できませんでした: {error}",
  "@doublesMatchSaveFailedMessage": {
    "description": "Message shown when doubles match information cannot be saved.",
    "placeholders": {
      "error": {
        "type": "String",
        "example": "network error"
      }
    }
  }''';

const String enMessages = r'''  "doublesMatchEditTitle": "Match status and final score",
  "@doublesMatchEditTitle": {
    "description": "Title for the doubles match status and final score dialog."
  },
  "doublesMatchStatusScheduledLabel": "Scheduled",
  "@doublesMatchStatusScheduledLabel": {
    "description": "Label for a doubles match that has not started."
  },
  "doublesMatchStatusInProgressLabel": "In progress",
  "@doublesMatchStatusInProgressLabel": {
    "description": "Label for a doubles match in progress."
  },
  "doublesMatchStatusCompletedLabel": "Completed",
  "@doublesMatchStatusCompletedLabel": {
    "description": "Label for a completed doubles match."
  },
  "doublesMatchScorePickerTitle": "Select score",
  "@doublesMatchScorePickerTitle": {
    "description": "Title for selecting a doubles match score."
  },
  "doublesMatchScoreUnsetLabel": "Clear score",
  "@doublesMatchScoreUnsetLabel": {
    "description": "Button label for clearing both doubles match scores."
  },
  "doublesMatchStartTimeLabel": "Start time",
  "@doublesMatchStartTimeLabel": {
    "description": "Label for a doubles match start time."
  },
  "doublesMatchEndTimeLabel": "End time",
  "@doublesMatchEndTimeLabel": {
    "description": "Label for a doubles match end time."
  },
  "doublesMatchSetCurrentTimeTooltip": "Set current time",
  "@doublesMatchSetCurrentTimeTooltip": {
    "description": "Tooltip for setting a match time to the current time."
  },
  "doublesMatchNoteLabel": "Match note",
  "@doublesMatchNoteLabel": {
    "description": "Input label for a doubles match note."
  },
  "doublesMatchSaveButton": "Save",
  "@doublesMatchSaveButton": {
    "description": "Button label for saving doubles match information."
  },
  "doublesMatchWinnerLabel": "Winner",
  "@doublesMatchWinnerLabel": {
    "description": "Label for the winning side of a completed doubles match."
  },
  "doublesMatchLoserLabel": "Loser",
  "@doublesMatchLoserLabel": {
    "description": "Label for the losing side of a completed doubles match."
  },
  "doublesMatchDrawLabel": "Draw",
  "@doublesMatchDrawLabel": {
    "description": "Label for a drawn doubles match."
  },
  "doublesMatchSavedMessage": "Match information saved",
  "@doublesMatchSavedMessage": {
    "description": "Message shown after doubles match information is saved."
  },
  "doublesMatchRefreshedMessage": "Match information refreshed",
  "@doublesMatchRefreshedMessage": {
    "description": "Message shown after doubles match information is refreshed."
  },
  "doublesMatchConflictMessage": "This match was updated on another device. Refresh the latest information.",
  "@doublesMatchConflictMessage": {
    "description": "Message shown when doubles match information has a revision conflict."
  },
  "doublesMatchIncompleteScoreMessage": "Enter both scores or leave both scores unset.",
  "@doublesMatchIncompleteScoreMessage": {
    "description": "Validation message shown when only one doubles match score is entered."
  },
  "doublesMatchTimeOrderErrorMessage": "End time must not be earlier than start time.",
  "@doublesMatchTimeOrderErrorMessage": {
    "description": "Validation message shown when a match end time is earlier than its start time."
  },
  "doublesMatchUnavailableMessage": "Schedule information required to edit this match is unavailable.",
  "@doublesMatchUnavailableMessage": {
    "description": "Message shown when required schedule information is unavailable for match editing."
  },
  "doublesMatchScheduleChangedMessage": "The schedule was updated on another device. Reload the latest schedule.",
  "@doublesMatchScheduleChangedMessage": {
    "description": "Message shown when the displayed schedule is stale before match editing."
  },
  "doublesMatchSaveFailedMessage": "Could not save match information: {error}",
  "@doublesMatchSaveFailedMessage": {
    "description": "Message shown when doubles match information cannot be saved.",
    "placeholders": {
      "error": {
        "type": "String",
        "example": "network error"
      }
    }
  }''';

void appendMessages(File file, String messages) {
  final String text = file.readAsStringSync();
  if (text.contains('"doublesMatchEditTitle"')) {
    stdout.writeln('skip: ${_relativePath(file.path)} already contains doubles messages');
    return;
  }

  final int closingIndex = text.lastIndexOf('\n}');
  if (closingIndex < 0) {
    throw StateError('Could not find closing brace in ${file.path}');
  }

  String prefix = text.substring(0, closingIndex).trimRight();
  if (!prefix.endsWith(',')) {
    prefix += ',';
  }

  file.writeAsStringSync('$prefix\n$messages\n}\n', flush: true);
  stdout.writeln('updated: ${_relativePath(file.path)}');
}

void removeTemporaryExtension() {
  final File l10nFile = File('${l10nDirectory.path}/l10n.dart');
  const String exportLine = "export 'doubles_match_l10n.dart';\n";
  final String l10nText = l10nFile.readAsStringSync();
  if (l10nText.contains(exportLine)) {
    l10nFile.writeAsStringSync(
      l10nText.replaceAll(exportLine, ''),
      flush: true,
    );
    stdout.writeln('updated: lib/l10n/l10n.dart');
  }

  final File extensionFile = File(
    '${l10nDirectory.path}/doubles_match_l10n.dart',
  );
  if (extensionFile.existsSync()) {
    extensionFile.deleteSync();
    stdout.writeln('deleted: lib/l10n/doubles_match_l10n.dart');
  }
}

String _relativePath(String path) {
  return path.substring(root.path.length + 1).replaceAll('\\', '/');
}

void main() {
  appendMessages(File('${l10nDirectory.path}/app_ja.arb'), jaMessages);
  appendMessages(File('${l10nDirectory.path}/app_en.arb'), enMessages);
  removeTemporaryExtension();

  final File script = File.fromUri(Platform.script);
  script.deleteSync();
  stdout.writeln('deleted: tool/apply_146_doubles_match_l10n.dart');
  stdout.writeln('next: flutter gen-l10n');
}
