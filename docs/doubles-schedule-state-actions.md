# ダブルス対戦表のschedule state更新

## 目的

ダブルス対戦表の再生成 / adoptで、表示中のschedule stateを古い前提のまま上書きしないための更新方針を整理する。

schedule stateの更新では、progress全体の再取得を前提にせず、現在表示しているgenerated scheduleとFirestore上の最新stateが一致していることを保存transaction内で確認する。

## schedule state

再生成 / adoptで扱う主なevent fieldは以下とする。

- `status`
- `currentGeneratedScheduleId`
- `adoptedGeneratedScheduleId`
- `adoptedAt`

`event.revision` はaggregate全体の変更検知用として引き続き更新するが、schedule state専用の競合判定には利用しない。

新しい `scheduleStateRevision` は追加せず、現在表示している `currentGeneratedScheduleId` をexpected stateとして利用する。

## 再生成

既存対戦表を再生成する場合は次の順序とする。

1. 確認ダイアログを表示する
2. event aggregateだけを取得し、adopt済みでないことと、最新の `currentGeneratedScheduleId` が表示中IDと一致することを確認する
3. coreで新しいgenerated scheduleを生成する
4. Firestore transaction内でも、最新の `currentGeneratedScheduleId` がexpected stateと一致し、adopt済みでないことを確認する
5. 条件が一致した場合だけ新しい `currentGeneratedScheduleId` を保存する
6. 保存成功後は新しいschedule responseとschedule stateだけをローカルへ反映する

事前確認から保存までの間に別端末でschedule stateが変わった場合は、transaction側のcompare-and-setで競合として扱う。

core生成後にcompare-and-setが競合した場合、生成済みsnapshotがeventから参照されず残ることがある。
そのsnapshotを古いstateで採用することはせず、eventの最新schedule stateを優先する。
未参照snapshotのcleanupが必要になった場合は別の運用・保守責務として扱う。

再生成前の確認ではprogress summary / match一覧を取得しない。

## adopt

adoptは表示中generated schedule IDをexpected stateとしてFirestore transactionへ渡す。

transaction内で次を確認する。

- 最新の `currentGeneratedScheduleId` が表示中IDと一致する
- まだadoptされていない

条件が一致した場合だけ、同じgenerated schedule IDを `adoptedGeneratedScheduleId` として保存する。

adopt成功後はrepositoryの更新結果をローカルへ直接反映し、通常の全体refreshは行わない。

## 競合時

schedule stateのcompare-and-setが失敗した場合は `ScheduleStateConflictException` として扱う。

競合後はevent aggregateだけを再取得する。

- generated schedule IDが変わっている場合
  - 最新generated scheduleだけを取得する
  - 古いprogress summary / match一覧は破棄する
- 同じgenerated scheduleが別端末でadoptされている場合
  - 現在のschedule表示とprogressは維持する
  - schedule stateだけをadopt済みへ更新する

この競合同期でもprogress summary / match一覧の再取得は行わない。

Firestore Webではtransaction callback内でDart例外の型が失われる場合があるため、schedule state競合はtransaction内では通常データとして返し、transaction完了後に `ScheduleStateConflictException` を再構築する。

## ローカル反映

repositoryのschedule state更新結果には最新event全体が含まれるが、現在画面へevent全体をそのまま差し替えない。

`mergeScheduleStateFragment()` でschedule stateだけを反映し、display / court settings等の現在のローカルstateを維持する。

部分反映時はローカルの `event.revision` を保存結果へ進めない。

これにより、同時に別fragmentが更新されていた場合でも、その内容を未反映のままaggregate revisionだけ最新として扱うことを避ける。

## loading範囲

初回生成と既存対戦表の再生成は表示を分ける。

- 表示できるscheduleがない生成中
  - match領域をloading表示にする
- 既存scheduleを再生成中
  - 現在の対戦表を表示したまま維持する
  - 再生成ボタン内だけ処理中表示にする

再生成 / adopt中は互いのschedule state操作とmanual refreshを抑止するが、display / court編集やplayer選択など、schedule stateと独立して保存できる操作は一律blockしない。

## Firestore Rules

既存Rulesではgenerate / adopt更新で変更可能fieldを限定している。

adoptでは保存済みの `currentGeneratedScheduleId` と同じIDだけをadoptできるため、repository側のcompare-and-set方針と整合する。

本整理ではRules自体の変更は行わない。
