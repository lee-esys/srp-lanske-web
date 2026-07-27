#!/usr/bin/env python3
import base64
import json
import re
import subprocess
import zlib
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib/l10n"
TEAM = ROOT / "lib/features/team_scheduler"
PAYLOAD = "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"
ENTRIES = json.loads(zlib.decompress(base64.b64decode(PAYLOAD)).decode("utf-8"))


def replace_required(text, old, new, label, minimum=1):
    count = text.count(old)
    if count < minimum:
        raise RuntimeError(f"{label}: expected at least {minimum} replacement(s), found {count}")
    return text.replace(old, new)


def regex_replace_required(text, pattern, replacement, label, minimum=1, flags=0):
    text, count = re.subn(pattern, replacement, text, flags=flags)
    if count < minimum:
        raise RuntimeError(f"{label}: expected at least {minimum} replacement(s), found {count}")
    return text


def split_top_level_args(raw):
    parts=[]
    start=0
    stack=[]
    quote=None
    escaped=False
    pairs={')':'(',']':'[','}':'{'}
    for i,ch in enumerate(raw):
        if quote:
            if escaped:
                escaped=False
            elif ch=='\\':
                escaped=True
            elif ch==quote:
                quote=None
            continue
        if ch in "'\"":
            quote=ch
        elif ch in '([{':
            stack.append(ch)
        elif ch in ')]}':
            if stack and stack[-1]==pairs[ch]:
                stack.pop()
        elif ch==',' and not stack:
            part=raw[start:i].strip()
            if part:
                parts.append(part)
            start=i+1
    part=raw[start:].strip()
    if part:
        parts.append(part)
    return parts


def split_named_arg(part):
    stack=[]
    quote=None
    escaped=False
    pairs={')':'(',']':'[','}':'{'}
    for i,ch in enumerate(part):
        if quote:
            if escaped:
                escaped=False
            elif ch=='\\':
                escaped=True
            elif ch==quote:
                quote=None
            continue
        if ch in "'\"":
            quote=ch
        elif ch in '([{':
            stack.append(ch)
        elif ch in ')]}':
            if stack and stack[-1]==pairs[ch]:
                stack.pop()
        elif ch==':' and not stack:
            return part[:i].strip(), part[i+1:].strip()
    return None, None


def convert_named_calls(text, method, order):
    needle=f'l10n.{method}('
    offset=0
    converted=0
    while True:
        start=text.find(needle, offset)
        if start<0:
            break
        open_pos=start+len(needle)-1
        depth=0
        quote=None
        escaped=False
        close_pos=None
        for i in range(open_pos, len(text)):
            ch=text[i]
            if quote:
                if escaped:
                    escaped=False
                elif ch=='\\':
                    escaped=True
                elif ch==quote:
                    quote=None
                continue
            if ch in "'\"":
                quote=ch
            elif ch=='(':
                depth+=1
            elif ch==')':
                depth-=1
                if depth==0:
                    close_pos=i
                    break
        if close_pos is None:
            raise RuntimeError(f'unclosed call: {method}')
        raw=text[open_pos+1:close_pos]
        values={}
        for part in split_top_level_args(raw):
            name,value=split_named_arg(part)
            if name:
                values[name]=value
        if all(name in values for name in order):
            replacement='l10n.'+method+'('+', '.join(values[name] for name in order)+')'
            text=text[:start]+replacement+text[close_pos+1:]
            offset=start+len(replacement)
            converted+=1
        else:
            offset=close_pos+1
    return text, converted


def add_arb_messages():
    for locale in ('ja','en'):
        path=L10N/f'app_{locale}.arb'
        data=json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=OrderedDict)
        for key,ja,en,description,placeholders in ENTRIES:
            data[key]=ja if locale=='ja' else en
            meta=OrderedDict(description=description)
            if placeholders:
                meta['placeholders']=OrderedDict(
                    (name, OrderedDict(type=spec[0], example=spec[1]))
                    for name,spec in placeholders.items()
                )
            data['@'+key]=meta
        path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def update_setup_page():
    path=TEAM/'presentation/team_setup_page.dart'
    text=path.read_text(encoding='utf-8')
    text=replace_required(text,'String get _teamDistributionText {','String _teamDistributionText(AppLocalizations l10n) {','distribution signature')
    text=replace_required(text,"return '${entry.key}人×${entry.value}チーム';",'return l10n.teamDistributionItem(entry.key, entry.value);','distribution item')
    text=regex_replace_required(text,r'\n  String _participantInputButtonLabel\(AppLocalizations l10n\) \{.*?\n  \}\n(?=\n  Future<void> _showParticipantNameInputDialog)', '', 'participant input label helper', flags=re.S)
    text=replace_required(text,'child: Text(l10n.cancel),','child: Text(l10n.cancelButton),','setup cancel')
    text=replace_required(text,'child: Text(_participantInputButtonLabel(l10n)),','child: Text(l10n.teamParticipantInputButton),','participant input button')
    text=replace_required(text,'l10n.teamDistributionSummary(_teamDistributionText)','l10n.teamDistributionSummary(_teamDistributionText(l10n))','distribution call')
    path.write_text(text,encoding='utf-8')


def update_participant_card():
    path=TEAM/'presentation/widgets/team_participant_name_input_card.dart'
    text=path.read_text(encoding='utf-8')
    text=regex_replace_required(text,r'\n  String _participantInputTitle\(AppLocalizations l10n\) \{.*?\n  \}\n(?=\n  Widget _buildTextField)', '', 'participant title helper', flags=re.S)
    text=replace_required(text,'_participantInputTitle(l10n),','l10n.teamParticipantInputButton,','participant title call')
    path.write_text(text,encoding='utf-8')


def update_imports_and_aliases():
    for path in TEAM.rglob('*.dart'):
        text=path.read_text(encoding='utf-8')
        text=text.replace("import '../../../l10n/app_localizations.dart';\nimport '../../../l10n/team_l10n.dart';", "import 'package:srp_lanske/l10n/l10n.dart';")
        text=text.replace("import '../../../../l10n/app_localizations.dart';\nimport '../../../../l10n/team_l10n.dart';", "import 'package:srp_lanske/l10n/l10n.dart';")
        aliases={
            'cancelDisplayNameEditButton':'cancelButton',
            'saveDisplayNameEditButton':'saveButton',
            'cancelRefreshBocciaScoreButton':'cancelButton',
            'cancelClearBocciaEndThrowLogsButton':'cancelButton',
            'saveBocciaScoreButton':'saveButton',
            'closeBocciaScoreDialogButton':'closeButton',
            'refreshLatestTeamScheduleButton':'refreshLatestButton',
            'refreshLatestInfo':'refreshLatestButton',
        }
        for old,new in aliases.items():
            text=re.sub(r'\bl10n\.'+re.escape(old)+r'\b','l10n.'+new,text)
        text=re.sub(r'\bl10n\.cancel\b','l10n.cancelButton',text)
        text=re.sub(r'\bl10n\.save\b','l10n.saveButton',text)
        for method,order in {
            'teamScheduleSummary':['teamCount','memberCount','concurrentMatchCount'],
            'teamCourtMatchTitle':['courtNo','matchTitle'],
            'teamChoiceLabel':['teamName','memberCount'],
            'bocciaScoreSummary':['redTeamName','redScore','blueTeamName','blueScore'],
            'bocciaScoreDialogMatchTitle':['redTeamName','blueTeamName'],
            'bocciaThrowCountSummary':['redCount','blueCount'],
            'bocciaThrowCountProgress':['count','maxCount'],
            'bocciaThrowOrderItem':['throwNo','playerName','sideLabel','boxNo'],
        }.items():
            text,_=convert_named_calls(text,method,order)
        path.write_text(text,encoding='utf-8')


def update_schedule_page():
    path=TEAM/'presentation/team_schedule_page.dart'
    text=path.read_text(encoding='utf-8')
    text=replace_required(text,"'Team $teamSlot'",'AppLocalizations.of(context).defaultTeamName(teamSlot)','team fallback')
    text=replace_required(text,"'Participant $playerSlot'",'AppLocalizations.of(context).defaultTeamMemberName(playerSlot)','participant fallback')
    text=replace_required(text,"\n              'vs',",'\n              l10n.teamMatchVsLabel,','standalone vs')
    old='''_isRestoreMode
                       ? l10n.teamScheduleRestoreFailedBody(message)
                       : l10n.teamScheduleGenerateFailedBody(message),'''
    new='''_isRestoreMode
                       ? (message.isEmpty
                           ? l10n.teamScheduleRestoreFailedBody
                           : l10n.teamScheduleRestoreFailedBodyWithDetail(message))
                       : (message.isEmpty
                           ? l10n.teamScheduleGenerateFailedBody
                           : l10n.teamScheduleGenerateFailedBodyWithDetail(message)),'''
    text=replace_required(text,old,new,'error body selection')
    path.write_text(text,encoding='utf-8')


def finish_l10n():
    barrel=L10N/'l10n.dart'
    text=barrel.read_text(encoding='utf-8')
    text=text.replace("export 'team_l10n.dart';\n",'')
    barrel.write_text(text,encoding='utf-8')
    (L10N/'team_l10n.dart').unlink()


def validate_source():
    joined='\n'.join(p.read_text(encoding='utf-8') for p in TEAM.rglob('*.dart'))
    forbidden=['team_l10n.dart','localeName.startsWith',"'参加者入力'", "\n              'vs',"]
    for item in forbidden:
        if item in joined:
            raise RuntimeError(f'forbidden source remains: {item}')


add_arb_messages()
update_setup_page()
update_participant_card()
update_imports_and_aliases()
update_schedule_page()
finish_l10n()
subprocess.run(['flutter','gen-l10n'],cwd=ROOT,check=True)
subprocess.run(['dart','format','lib/'],cwd=ROOT,check=True)
validate_source()
subprocess.run(['flutter','analyze'],cwd=ROOT,check=True)
subprocess.run(['flutter','test'],cwd=ROOT,check=True)
