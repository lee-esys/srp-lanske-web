from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
L10N_DIR = ROOT / "lib" / "l10n"

JA_MESSAGES = r'''
  "doublesMatchEditTitle": "試合状態・最終スコア",
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
  }
'''.strip("\n")

EN_MESSAGES = r'''
  "doublesMatchEditTitle": "Match status and final score",
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
  }
'''.strip("\n")


def append_messages(path: Path, messages: str) -> None:
    text = path.read_text(encoding="utf-8")
    if '"doublesMatchEditTitle"' in text:
        print(f"skip: {path.relative_to(ROOT)} already contains doubles messages")
        return

    closing_index = text.rfind("\n}")
    if closing_index < 0:
        raise RuntimeError(f"could not find closing brace in {path}")

    prefix = text[:closing_index].rstrip()
    if not prefix.endswith(","):
        prefix += ","

    updated = f"{prefix}\n{messages}\n}}\n"
    path.write_text(updated, encoding="utf-8", newline="\n")
    print(f"updated: {path.relative_to(ROOT)}")


def remove_temporary_extension() -> None:
    l10n_path = L10N_DIR / "l10n.dart"
    export_line = "export 'doubles_match_l10n.dart';\n"
    text = l10n_path.read_text(encoding="utf-8")
    if export_line in text:
        l10n_path.write_text(
            text.replace(export_line, ""),
            encoding="utf-8",
            newline="\n",
        )
        print("updated: lib/l10n/l10n.dart")

    extension_path = L10N_DIR / "doubles_match_l10n.dart"
    if extension_path.exists():
        extension_path.unlink()
        print("deleted: lib/l10n/doubles_match_l10n.dart")


def main() -> None:
    append_messages(L10N_DIR / "app_ja.arb", JA_MESSAGES)
    append_messages(L10N_DIR / "app_en.arb", EN_MESSAGES)
    remove_temporary_extension()

    script_path = Path(__file__).resolve()
    script_path.unlink()
    print("deleted: tool/apply_146_doubles_match_l10n.py")
    print("next: flutter gen-l10n")


if __name__ == "__main__":
    main()
