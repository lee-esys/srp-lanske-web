# ダブルス試合結果入力の保存継続と未保存制御

## 目的

確定済みのダブルス対戦表で、試合状態・最終スコア・開始／終了時刻・試合メモを保存した後も、同じ入力ダイアログを開いたまま操作を継続できるようにする。

保存失敗や複数端末によるrevision競合が発生した場合も、入力中の内容を失わない。

## 編集状態

試合結果入力では、次の2つを分けて扱う。

- `baseline`
  - repositoryへ最後に保存された `ScheduleMatchProgress`
  - 次回保存に使用するrevisionを含む
- `draft`
  - ダイアログで現在入力している値
  - 試合状態、両側スコア、開始時刻、終了時刻、メモを含む

`baseline`から作成した入力値と`draft`を比較し、異なる場合を未保存状態とする。
入力を保存済み値へ戻した場合は、未保存状態を解除する。

## 保存フロー

```text
試合カードを選択
  ↓
対象試合の最新ScheduleMatchProgressを取得
  ↓
baselineとdraftを初期化
  ↓
ダイアログから保存callbackを呼ぶ
  ↓
DoublesMatchProgressService
  ↓
ScheduleProgressRepository.saveMatch
  ├─ baselineのrevisionをexpectedRevisionとして使用
  ├─ match documentを更新
  └─ progress summaryを更新
  ↓
保存済みScheduleMatchProgressとsummaryを返す
  ↓
保存結果を新しいbaselineとdraftへ反映
  ↓
未保存状態を解除し、ダイアログを維持
```

保存結果を新しいbaselineとして使う。
送信前のdraftをそのままbaselineにはしない。

repository／serviceでは、メモのtrim、状態に応じた時刻補完、revision更新などが行われるため、保存後の値を画面状態へ戻す必要がある。

## 連続保存とrevision

1回目の保存成功後に返された試合revisionを、2回目の保存時の`expectedRevision`として使用する。

ダイアログを開いた時点のrevisionを使い続けると、自分自身の直前の保存と競合するため、保存成功ごとにbaselineを更新する。

## 保存失敗・競合

保存失敗またはrevision競合時は、次の状態を維持する。

- ダイアログを閉じない
- draftを変更しない
- baselineを変更しない
- 保存中状態だけを解除する
- ダイアログ内へエラーを表示する

競合時に最新値を自動でdraftへ反映しない。
未保存入力との3-way差分解消は対象外とする。

## 閉じる操作

未保存変更がない場合は、そのまま閉じる。

未保存変更がある場合は、次の選択肢を表示する。

- 保存して閉じる
- 保存せず閉じる
- キャンセル

「保存して閉じる」は保存成功時だけダイアログを閉じる。
保存失敗・競合時はダイアログとdraftを維持する。

ダイアログ領域外のタップでは閉じない。
保存中は、重複保存と閉じる操作を抑止する。

## 画面反映

保存成功後は以下を更新する。

- 対象試合カード
- ラウンド完了表示
- 進行summary
- ブラウザローカルの対戦表履歴

通常生成画面と共有URL復元画面は、共通の`ScheduleRoundsView`と試合結果入力ダイアログを利用する。
