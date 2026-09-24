# ダブルスイベント表示情報の保存と競合制御

## 目的

ダブルス対戦表のevent所有者、イベントタイトル、イベントメモ、プレイヤー表示名、コート表示設定を、既存aggregate形式を維持しながら安全に保存・更新する方針を整理する。

複数端末から異なる種類の情報が更新された場合でも、無関係な変更を理由に不要な競合を発生させず、古いaggregate全体で他端末の変更を巻き戻さないことを目的とする。

## 保存schema

`events/{publicId}` は `schemaVersion: 2` のaggregate形式として保存する。

主な構成は以下とする。

```text
events/{publicId}
  schemaVersion: 2

  event
    id
    publicId
    ownerUid
    title
    memo
    currentGeneratedScheduleId
    adoptedGeneratedScheduleId
    revision
    ...

  revisions
    display
    courtSettings

  players[]
  share
  importRecord
  courtSettings[]
```

### ownership

`event.ownerUid` はevent所有者のFirebase Auth UIDを保持する。

- 新規event作成時は、既存のFirebase Auth sessionを利用する
- signed-outの場合は、eventを実際に保存する操作時にAnonymous sessionを作成する
- 画面を開いただけ、または共有URLを閲覧しただけではAnonymous sessionを作成しない
- Anonymous userとregistered accountのどちらもFirebase Auth UIDを同じ基準で扱う
- `ownerUid == null` はlegacy / owner不明eventとして扱う
- publicId、共有URL、端末内履歴はownershipの証明に利用しない

通常のevent更新APIではownerUidを変更しない。Anonymous userから既存accountへのownership移管は専用フローで扱う。

### aggregate revision

`event.revision` はaggregate全体で変更が発生したことを表すrevisionとして維持する。

以下のような更新で増加する。

- event title / memo / player display name
- court display settings
- current generated schedule
- adopted generated schedule

ただし、構造編集の競合判定にはaggregate revisionを直接利用しない。

### fragment revision

編集・競合の意味上の単位として、aggregate直下にfragment revisionを持つ。

```text
revisions.display
  event.title
  event.memo
  players[].displayName

revisions.courtSettings
  courtSettings[]
```

display更新では `event.revision` と `revisions.display` を増加させ、`revisions.courtSettings` は変更しない。

court settings更新では `event.revision` と `revisions.courtSettings` を増加させ、`revisions.display` は変更しない。

generated scheduleの再生成・採用等では `event.revision` のみを増加させ、display / court settings revisionは変更しない。

これにより、たとえば別端末で対戦表が再生成された後でも、表示情報自体が変更されていなければ、編集開始時に取得したdisplay revisionを使って表示情報を保存できる。

## legacy互換

schemaVersion 1など、`ownerUid` または `revisions` を持たない既存eventは引き続き読み取れる。

- `ownerUid` がない場合: `null`
- `revisions.display` がない場合: 読み込み時点の `event.revision`
- `revisions.courtSettings` がない場合: 読み込み時点の `event.revision`

legacy eventへ次の非no-op更新が行われた際に、schemaVersion 2とfragment revisionを保存する。

たとえば、legacy eventの `event.revision == 4` の状態でgenerated scheduleのみを更新する場合、更新後は概念上次の状態になる。

```text
event.revision: 5
revisions.display: 4
revisions.courtSettings: 4
```

schedule stateの更新によってdisplay / court settingsの競合基準まで進めないことが重要となる。

legacy eventのownerUidを共有URLや端末内履歴から推測して補完することはしない。

## ownership query

所有eventの取得は `event.ownerUid` を正本として行う。

```text
events
  where event.ownerUid == current Firebase Auth UID
```

このquery基盤はMy Page等の将来機能から利用する。端末内履歴をownership一覧の正本にはしない。

## 更新単位

### イベント情報と全プレイヤー表示名

イベントタイトル、メモ、全プレイヤー表示名は、まとめて編集・保存するdisplay fragmentとして扱う。

保存時には、編集開始時の `revisions.display` を `expectedDisplayRevision` として渡す。

Firestoreではtransaction内で最新Documentを取得し、次を行う。

1. 入力されたplayer IDが現在のplayer IDと一致することを確認する
2. 保存済みの値と入力値がすべて同じ場合はno-op成功とする
3. 値が異なり、display revisionが一致しない場合は保存しない
4. display revisionが一致した場合だけ、タイトル、メモ、players配列、aggregate revision、display revision、更新日時を更新する

generated schedule、採用状態、共有情報、取り込み情報、コート表示設定など、変更対象外の情報は更新しない。

### コート表示設定

revision指定の更新APIでは、編集開始時の `revisions.courtSettings` を `expectedCourtSettingsRevision` として渡す。

no-op判定後にcourt settings revisionを確認し、一致した場合だけcourt表示設定、aggregate revision、court settings revision、更新日時を更新する。

コート表示は対戦組み合わせではなく、当日の案内に使う表示情報として扱う。対戦表の採用後も変更できる。

## 編集UIのライフサイクル

対戦表作成直後の画面と共有URLから復元した画面は、同じイベント情報編集UIを利用する。

ダイアログでは次をまとめて編集する。

- イベントタイトル
- イベントメモ
- 全プレイヤーの現在の表示名

操作時は次の順序とする。

1. ダイアログを開く前に最新情報を取得する
2. 最新aggregateの `revisions.display` を保存基準としてダイアログを開く
3. 保存成功時だけダイアログを閉じる
4. 競合時は入力内容を保持したまま最新情報を取得する
5. 最新のdisplay revisionへ保存基準を更新し、利用者が確認・再保存できるようにする

最新情報の取得範囲や保存中の画面挙動は、更新挙動を扱う別Issueで継続して整理する。

## 競合時の扱い

同じfragmentへ異なる値を保存しようとしてrevisionが一致しない場合は、`EventRevisionConflictException` を返す。

異なるfragmentの変更では競合させない。

例:

- display編集中にgenerated scheduleが変わる: display保存可能
- display編集中にcourt labelが変わる: display保存可能
- display編集中に別端末でtitleが変わる: display競合
- court label編集中に別端末でtitleが変わる: court保存可能
- court label編集中に別端末でcourt labelが変わる: court競合

base、最新値、入力値を比較する高度な3-way競合解消は別Issueで扱う。

## Document分割との関係

本方針では、fragment revisionを導入するためだけにFirestore Documentを分割しない。

`events/{publicId}` aggregateを維持しながら、保存API・revision・Permissionの論理境界を分ける。

将来、取得量、Rules、独立更新頻度など別の理由から物理Document分割が必要になった場合は、その時点の実装と利用状況を確認して改めて判断する。
