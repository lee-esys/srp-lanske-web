#!/usr/bin/env python3
from pathlib import Path

SCRIPT = Path(__file__).with_name("migrate_team_l10n.py")
source = SCRIPT.read_text(encoding="utf-8")

old = '''    old=\'\'\'_isRestoreMode
                       ? l10n.teamScheduleRestoreFailedBody(message)
                       : l10n.teamScheduleGenerateFailedBody(message),\'\'\'
    new=\'\'\'_isRestoreMode
                       ? (message.isEmpty
                           ? l10n.teamScheduleRestoreFailedBody
                           : l10n.teamScheduleRestoreFailedBodyWithDetail(message))
                       : (message.isEmpty
                           ? l10n.teamScheduleGenerateFailedBody
                           : l10n.teamScheduleGenerateFailedBodyWithDetail(message)),\'\'\'
    text=replace_required(text,old,new,\'error body selection\')'''

new = '''    pattern = (
        r\'_isRestoreMode\\s*\'
        r\'\\?\\s*l10n\\.teamScheduleRestoreFailedBody\\(message\\)\\s*\'
        r\':\\s*l10n\\.teamScheduleGenerateFailedBody\\(message\\),\'
    )
    replacement = \'\'\'_isRestoreMode
                       ? (message.isEmpty
                           ? l10n.teamScheduleRestoreFailedBody
                           : l10n.teamScheduleRestoreFailedBodyWithDetail(message))
                       : (message.isEmpty
                           ? l10n.teamScheduleGenerateFailedBody
                           : l10n.teamScheduleGenerateFailedBodyWithDetail(message)),\'\'\'
    text=regex_replace_required(
        text,
        pattern,
        replacement,
        \'error body selection\',
    )'''

if old not in source:
    raise RuntimeError("migration script patch target was not found")

patched = source.replace(old, new, 1)
namespace = {
    "__file__": str(SCRIPT),
    "__name__": "__main__",
}
exec(compile(patched, str(SCRIPT), "exec"), namespace)
