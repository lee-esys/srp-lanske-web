# ダブルスイベント表示情報の保存と競合制御

## 目的

ダブルス対戦表のイベントタイトル、イベントメモ、プレイヤー表示名、コート表示設定を更新する際に、古いイベントaggregateで他端末の変更を巻き戻さないための保存方針を整理する。

## 保存schema

`events/{publicId}` は、現行のaggregate形式を `schemaVersion: 1` として扱う。

イベント表示情報として以下を保存する。

- `event.title`: 現在のイベントタイトル
- `event.memo`: イベント単位のメモ
- `event.revision`: イベントaggregate上の共有表示情報を更新するためのrevision
- `players[].initialDisplayName`: 対戦表生成時の表示名
- `players[].displayName`: 現在の表示名
- `courtSettings[]`: コート表示設定

既存Documentとの互換性のため、フィールドがない場合は以下として読み込む。

- `event.memo`: 空文字
- `players[].initialDisplayName`: 同じplayerの `displayName`

今回の追加は既存形式へ省略可能なフィールドを追加するため、schema versionは1のままとする。

## 更新単位

### イベント情報と全プレイヤー表示名

イベントタイトル、メモ、全プレイヤー表示名は、まとめて編集・保存する単位として扱う。

保存時には、画面で最新情報を取得した際の `event.revision` を `expectedRevision` として渡す。

Firestoreではtransaction内で最新Documentを取得し、次を行う。

1. 入力されたplayer IDが現在のplayer IDと一致することを確認する
2. 保存済みの値と入力値がすべて同じ場合はno-op成功とする
3. 値が異なり、revisionが一致しない場合は保存しない
4. revisionが一致した場合だけ、タイトル、メモ、players配列、revision、更新日時を更新する

生成済み対戦表ID、採用状態、共有情報、取り込み情報、コート表示設定など、変更対象外の情報は更新しない。

### コート表示設定

revisionを指定する更新APIでは、同じくno-op判定後にrevisionを確認し、コート表示設定、revision、更新日時だけを更新する。

既存UIとの互換用APIもFirestore transactionによる部分更新を利用し、古いaggregate全体の保存は行わない。

## 競合時の扱い

異なる値を保存しようとしてrevisionが一致しない場合は、`EventRevisionConflictException` を返す。

UIでは競合した入力を自動マージせず、ダイアログを閉じないまま最新情報を取得し、ユーザーが内容を確認して再編集できる状態にする。

base、最新値、入力値を比較する高度な競合解消は別Issueで扱う。

## 将来拡張

外部サービス上のplayer ID、レベル、年代、性別などは、取得形式と正規化方法が確定してからイベント時点のsource snapshotとして追加する。

ポット分けはplayer属性ではなく、対戦表生成条件側のポット情報として扱う。

将来、プレイヤー詳細の個別編集を追加する場合は、プレイヤー単位revisionまたはDocument分割を検討する。
