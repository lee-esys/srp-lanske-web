# web MVP の保存対象・復元方針・入力導線

Refs: #12 / #11

## 目的

共有URL前提の MVP を実装する前に、web 側で保存する情報、復元する範囲、入力導線、web / core のデータ所有範囲を整理する。

このドキュメントでは、フェーズ3の後続 Issue である保存モデル設計、テニスベア取り込み、共有URL復元、generate / adopt 導線の実装時に迷わないよう、MVP の前提を固定する。

## 前提

ver0.1 の web MVP では、ログインなしで使える共有URL前提の導線を優先する。

テニスベア取り込みは便利機能ではなく、MVP 必須の入力導線として扱う。ただし、自動スクレイピングやログイン情報の取得・保持はしない。主催者が URL やテキストを手動で貼り付け、取り込みボタンを押して event / participant 候補を作成する。

共有URLは主導線とし、作成者自身も共有URLから入り直す前提にする。MVPでは ownership を扱わないため、共有URLを知っている人は生成結果を表示し、採用できるものとする。

## 1. web 側で保存する対象

web 側では、共有URLから MVP として再表示するために必要な情報を保存する。

### 1.1 event

`event` は、対戦表生成と共有表示の中心になる情報を持つ。

保存対象の候補は以下。

* イベント名
* 日時
* 場所 / コート情報
* コート数
* 生成条件
* source_type
* source_url
* status

生成に必須なのは、コート数、参加者数 / 参加者一覧、schedule_type などの生成条件である。

表示・共有に必要なのは、イベント名、参加者表示名、対戦表である。

日時、場所、テニスベアURLなどは表示上有用だが、generate の必須入力とは分けて考える。

### 1.2 participant

`participant` は、このイベントに参加する表示対象を表す。

保存対象の候補は以下。

* 表示名
* 並び順
* 参加状態
* slot / assignment を表示名に解決するための情報
* source_display_name
* source_user_id 相当
* source_profile_url
* imported_player_metadata

core は player 名を知らない。

core が返す slot / assignment を、web 側で participant の表示名に解決する。

### 1.3 import / source

`import` / `source` は、テニスベア等から取り込んだ元情報を表す。

保存対象の候補は以下。

* source_type
* source_url
* pasted_text
* imported_at
* 抽出された event 候補
* 抽出された participant 候補
* import_status

`source_type` は以下を想定する。

* tennisbear
* tennisoff
* manual
* unknown

ver0.1 の実装対象はテニスベア優先だが、保存モデルとしては外部イベント情報の取り込みとして扱い、将来テニスオフ等を追加できる余地を残す。

### 1.4 share

`share` は、共有URLに関する情報を持つ。

ver0.1 ではログインなしで使うため、共有URLを知っている人が再表示できることを優先する。

ただし、将来的に共有URLの有効期限や再共有の扱いを拡張する可能性があるため、share は event に埋め込まず、独立した保存対象として扱う。

保存対象の候補は以下。

* public_id
* 共有URL
* 公開状態
* event への参照
* expires_at
* revoked_at
* created_at

public_id は event 作成時、または share 作成時に発行する。

MVPでは共有URLを主導線にするため、event を共有URLから復元できることを優先する。

ログインなしで作成した場合、期限切れ後の再共有はできない可能性がある。この点は ver0.1 では許容し、将来ログインや管理導線を作るときに再検討する。

### 1.5 generated_schedule_ref

web 側では generated_schedule 本体は持たず、参照として `generated_schedule_ref` を持つ。

保存対象の候補は以下。

* event への参照
* last_displayed_generated_schedule_id
* adopted_generated_schedule_id

画面更新、再取得、共有URLからの復元時は、web 側に保存した generated_schedule_id を使って core の get API から再取得する。

web 側に保存するのは、対戦表本体ではなく、どの generated_schedule を表示するかの参照情報とする。

### 1.6 ver0.1 では扱わないもの

ver0.1 では、以下は保存対象にしない。

* 対戦結果
* スコア
* 勝敗
* 実施済み状態
* 途中終了

これらは ver0.2 以降で扱う。

## 2. 復元対象

共有URL / リロード時に復元する最低ラインは、生成結果画面全体とする。

具体的には以下を復元対象にする。

* event name
* court count
* participant display names
* adopted または最後に表示していた generated_schedule_id
* core get による対戦表表示

inspection / quality_score は core 側には存在するが、ver0.1 web では表示対象にしない。

そのため、共有URL / リロード時の MVP 復元対象にも含めない。

### 2.1 復元時の表示方針

adopted_generated_schedule_id がある場合は、採用済み対戦表を表示する。操作カードは非表示にする。

adopted_generated_schedule_id がなく、last_displayed_generated_schedule_id がある場合は、最後に表示していた生成結果を表示する。この場合は「再生成」「採用」を表示してよい。

generated_schedule_id がない場合は、event / participant 入力画面を表示し、「この内容で生成」を表示する。

### 2.2 core get 失敗時

共有URLから event は復元できたが、core get に失敗する場合がある。

その場合は、イベント名・参加者名は表示し、対戦表部分に「対戦表を取得できませんでした」と表示する。あわせて再取得ボタンを表示する。

## 3. 入力導線

### 3.1 基本方針

web では、クリップボードからの自動読み取りには依存しない。

MVP の基本導線は以下とする。

1. 主催者がテニスベア等のURLまたはテキストを手動で貼り付ける
2. 「取り込み」ボタンを押す
3. URL / テキストを検証する
4. event / participant 候補を抽出する
5. 抽出結果を入力フォームへ反映する
6. 主催者が必要に応じてフォーム上で修正する
7. 「この内容で生成」を押す
8. 生成結果画面へ遷移する

### 3.2 バリデーション方針

手動貼り付け自体は許可する。

ただし、「取り込み」ボタン押下時に検証し、取り込み対象外であれば event / participant には反映しない。

失敗時は入力内容を消さず、エラーを表示する。

エラー文言例は以下。

* 取り込み対象のURLではありません
* イベント情報を読み取れませんでした
* 参加者情報が見つかりませんでした
* 貼り付け内容を確認してください

### 3.3 用語整理

抽出結果と生成結果は別物として扱う。

抽出結果は、貼り付けたテキスト / URL から読み取った event / participant 候補である。

生成結果は、core API が返した対戦表候補である。

生成結果には以下を含む。

* generated_schedule_id
* rounds
* assignment

### 3.4 主催者確認

「主催者確認」とは、抽出結果をフォームに反映したあと、主催者が入力内容を確認し、「この内容で生成」を押すこととする。

抽出結果専用の確認・編集画面は作らない。

イベント名や参加者名の修正は、通常の入力フォーム上で行う。

### 3.5 文言

入力側の文言は以下とする。

* この内容で生成

対戦表側の文言は以下とする。

* 再生成
* 採用
* 採用済み

「確定」は、入力確定と対戦表採用の両方に見えて紛らわしいため、MVPでは避ける。

### 3.6 生成結果画面

生成結果画面では、対戦表表示を優先する。

イベント情報・参加者一覧は常時カード表示せず、イベント名タップ等で詳細表示する方向を検討する。

MVPでの操作は以下のみ。

* 再生成
* 採用

「採用」後は操作カードを非表示にする。

## 4. web / core のデータ所有範囲

### 4.1 web 側が持つもの

web 側は以下を持つ。

* event 情報
* participant 表示情報
* テニスベア等の取り込み情報
* source_type / source_url
* pasted_text
* public_id
* 共有URL
* generated_schedule_id の参照
* adopted_generated_schedule_id
* last_displayed_generated_schedule_id

### 4.2 core 側が持つもの

core 側は以下を持つ。

* generated_schedule 本体
* assignment
* rounds
* adopted 状態
* adopted_at
* inspection
* quality_score
* algorithm_version

### 4.3 participant / player の考え方

participant は「このイベントに参加する表示対象」とする。

player は、取り込み元から得た人物情報、または将来の人物マスタになり得る概念として扱う。

ただし、ver0.1 MVP の時点では player の設計を強く固定しない。

実装時点では、まず participant を中心に扱い、テニスベア取り込みで得られる以下のような情報は、将来利用できる metadata として保持できる余地を残す。

* source_display_name
* display_name
* テニスベアレベル
* 性別
* source_user_id 相当
* source_profile_url
* imported_player_metadata

これらを participant に持たせるか、player / source_player 的な別概念として分けるかは、#14 の保存モデル設計時に改めて判断する。

core には player 情報を渡さない。

core は player 名・レベル・性別を知らず、web 側が slot / assignment を participant 表示名に解決する。

## 5. 状態遷移

MVPでは、event を中心に状態を整理する。

画面単位ではなく、event が今どの状態かを基準にする。

昔ながらの Web 画面でいう input → confirm → complete のような画面遷移だけでなく、1画面内で入力状態・生成結果・採用済み表示が変わる前提で整理する。

### 5.1 状態一覧

#### initial

まだ event が作られていない状態。

* event 未保存
* participant 未保存
* generated_schedule_ref なし

#### editing_input

主催者がイベント情報・参加者情報を入力している状態。

* URL / テキスト貼り付け
* 直接入力
* event / participant 入力中
* まだ generate は実行していない

#### import_failed

取り込みボタンを押したが、URL / テキストから event / participant 候補を抽出できなかった状態。

* pasted_text / source_url は入力欄に残す
* event / participant には反映しない
* エラーを表示する

#### imported_to_input

取り込みに成功し、抽出結果を入力フォームに反映した状態。

* event 候補がフォームに入っている
* participant 候補がフォームに入っている
* 主催者はフォーム上で必要に応じて修正できる
* 抽出結果専用の確認・編集画面は作らない

#### generated_preview

core generate 実行後、生成結果を表示している状態。

* event / participant は web 側に保存済み
* core から generated_schedule_id が返っている
* web 側では last_displayed_generated_schedule_id を保持する
* 操作は「再生成」「採用」

#### adopted

主催者が生成結果を採用した状態。

* core 側で adopted 状態になる
* web 側では adopted_generated_schedule_id を保持する
* 操作カードは非表示にする

#### restored

共有URL / リロードから復元した状態。

* public_id から web 側 event を取得する
* event / participant / generated_schedule_ref を復元する
* generated_schedule_id を使って core get する
* 対戦表を再表示する

restored は DB 上の状態というより、共有URL / リロードから入ったときの復元処理を表す。

### 5.2 保存状態として持つもの

DB上の状態は細かくしすぎない。

候補は以下。

* draft
* generated
* adopted

UI上だけで扱う状態は以下。

* initial
* editing_input
* import_failed
* imported_to_input
* restored

### 5.3 状態遷移

#### initial → editing_input

条件は、主催者が直接入力を始める、または URL / テキストを貼り付けること。

入力中は原則ローカル状態とし、DB保存は必須ではない。

#### editing_input → import_failed

条件は、「取り込み」ボタン押下後に、URL / テキストが対象外、または event / participant を抽出できないこと。

event / participant には反映しない。

入力欄の pasted_text / source_url は残し、エラーを表示する。

#### editing_input → imported_to_input

条件は、「取り込み」ボタン押下後に、event / participant 候補を抽出できたこと。

抽出結果をフォームに反映する。

import 情報の保存方法は #14 で設計する。

#### imported_to_input → generated_preview

条件は、主催者が「この内容で生成」を押し、入力内容が generate 可能で、core generate が成功すること。

web 側に event / participant / import / share を保存する。

core から返った generated_schedule_id を generated_schedule_ref として保存し、last_displayed_generated_schedule_id を更新する。

public_id は event 作成時に発行する。

表示は生成結果画面とし、操作は「再生成」「採用」とする。

#### generated_preview → generated_preview

条件は、「再生成」を押し、core generate が再度成功すること。

新しい generated_schedule_id を last_displayed_generated_schedule_id に保存する。

adopted_generated_schedule_id は更新しない。

過去の generated_schedule_id 履歴は ver0.1 では保持しない。

MVPでは最後に表示している generated_schedule_id だけ保持する。

#### generated_preview → adopted

条件は、「採用」を押し、core adopt が成功すること。

core 側で adopted 状態になる。

web 側で adopted_generated_schedule_id を保存し、event.status を adopted にする。

表示は採用済み対戦表とし、操作カードを非表示にする。

#### adopted → restored

条件は、共有URLからアクセス、またはリロードし、public_id から event を取得でき、adopted_generated_schedule_id で core get に成功すること。

採用済み対戦表、イベント名、参加者名を表示し、操作カードは表示しない。

#### generated_preview → restored

条件は、採用前の共有URL / リロードで、last_displayed_generated_schedule_id による core get に成功すること。

最後に表示していた生成結果を表示し、再生成 / 採用を表示する。

ownership は ver0.1 では扱わない。

MVPでは、共有URLを知っている人が採用できるものとする。

作成者も共有URLから入り直す前提のため、共有URLベースの操作を許容する。

### 5.4 共有URLでの操作範囲

MVPでは、共有URLを知っている人は生成結果を表示し、採用できるものとする。

ログインなし MVP では、作成者と閲覧者の ownership は扱わない。

また、将来ログインを実装した後も、ログインなしで作成された対戦表については、ログインユーザーに紐づかない共有URLベースの対戦表として扱う。

そのため、共有URLを知っている人が採用できる状態は許容する。

### 5.5 保存タイミング

入力途中の自動保存は行わない。

Google Forms のような入力中保存は ver0.1 では扱わない。

MVPでは、「この内容で生成」ボタンを押したタイミングで web 側の event / participant / import / share を保存する。

保存後に core generate を呼び、generate 成功後に generated_schedule_id を generated_schedule_ref として保存する。

public_id は event 作成時に発行する。

### 5.6 再生成時

再生成時の履歴は保持しない。

MVPでは、再生成に成功した場合、last_displayed_generated_schedule_id を新しい generated_schedule_id で上書きする。

過去に表示していた generated_schedule の履歴は web 側では扱わない。

### 5.7 adopt 後の扱い

ver0.1 MVPでは、adopt 後の全体再生成は行わない。

採用後は操作カードを非表示にし、採用済み対戦表として表示する。

ver0.2 以降では、以下のような機能を別途検討する。

* 対戦成績入力後の次対戦生成
* 手動入れ替え後の続き生成
* 一部変更・調整
* 成績入力済み状態を考慮した生成

ただし、採用済み対戦表全体の単純な再生成は不要とする。

### 5.8 状態遷移の結論

* 入力中は原則ローカル状態
* 入力途中の自動保存はしない
* 「この内容で生成」押下時に web 側 event / participant を保存する
* event 作成時に public_id を発行する
* generate 成功後、last_displayed_generated_schedule_id を保存する
* 再生成時は last_displayed_generated_schedule_id を上書きする
* 再生成履歴は保持しない
* 採用時は adopted_generated_schedule_id を保存する
* adopt 後は操作カードを非表示にし、全体再生成はさせない
* 共有URL / リロード時は public_id から event を復元し、generated_schedule_id で core get する
* MVPでは、共有URLを知っている人が採用できる

## 6. 後続Issueへの引き渡し

#12 の整理結果は、フェーズ3後続Issueの前提として扱う。

#12 完了時点では、後続Issueへ一括コメントはしない。

#13 以降に着手するとき、#12 の引き渡し内容をそのIssueの冒頭確認として使う。

必要なら、そのIssueの作業開始時に #12 の該当箇所だけをコメントとして転記する。

### #13 テニスベア情報取り込みの MVP 方針と画面説明を整理する

引き渡す内容は以下。

* テニスベア取り込みは MVP 必須導線とする
* 自動スクレイピング・認証情報保持はしない
* クリップボード自動読み取りには依存しない
* 手動貼り付け + 取り込みボタンを基本導線にする
* 抽出結果専用の確認画面は作らず、入力フォームへ反映する
* 主催者確認とは「この内容で生成」を押すこととする

### #14 event / participant / import / share の保存モデルを設計・実装する

引き渡す内容は以下。

* web 側は event / participant / import / share / generated_schedule_ref を持つ
* generated_schedule 本体は web 側では持たない
* web 側は generated_schedule_id の参照を持ち、必要時に core get で再取得する
* public_id は event 作成時に発行する
* 入力中の自動保存はしない
* 「この内容で生成」押下時に event / participant / import / share を保存する
* participant と player の分離余地を残す
* 対戦結果・スコア・勝敗は ver0.1 では扱わない

### #15 core API URL の環境切り替えを整理する

引き渡す内容は以下。

* generate / get / adopt の API 接続を前提にする
* 共有URL / リロード復元時は generated_schedule_id で core get する
* core API URL の環境切り替えは、本番共有URLの復元確認に必要

### #16 テニスベア貼り付けテキストから event / participant 候補を取り込む

引き渡す内容は以下。

* source_type は tennisbear / tennisoff / manual / unknown を想定する
* 取り込みボタン押下時に検証する
* 対象外URLや抽出失敗時は event / participant に反映しない
* 入力内容は消さず、エラー表示する
* 抽出結果は event / participant 候補として入力フォームに反映する
* テニスベアレベル・性別・プロフィールURL等は metadata として保持できる余地を残す

### #17 public_id / generated_schedule_id / adopted schedule を event に紐づける

引き渡す内容は以下。

* web 側は generated_schedule_ref を持つ
* last_displayed_generated_schedule_id を保持する
* adopted_generated_schedule_id を保持する
* 再生成時は last_displayed_generated_schedule_id を上書きする
* 再生成履歴は保持しない
* 採用時は adopted_generated_schedule_id を保存する
* adopted 状態の正は core 側とする

### #18 共有URL / リロードから event・participant・generated_schedule を復元する

引き渡す内容は以下。

* public_id から web 側 event を取得する
* event / participant / generated_schedule_ref を復元する
* generated_schedule_id を使って core get する
* adopted_generated_schedule_id があれば採用済み対戦表を表示する
* adopted がなければ last_displayed_generated_schedule_id を表示する
* core get 失敗時は event / participant を表示し、対戦表取得失敗を表示する

### #19 generate / 再生成 / adopt の web 導線を仕上げる

引き渡す内容は以下。

* 入力側の文言は「この内容で生成」
* 生成結果側の操作は「再生成」「採用」
* 採用後は「採用済み」として表示する
* adopt 後は操作カードを非表示にする
* adopt 後の全体再生成は行わない
* MVPでは、共有URLを知っている人が採用できる

### #20 URLコピー導線を実装する

引き渡す内容は以下。

* public_id から共有URLを作る
* 共有URLは MVP の主導線とする
* 作成者も共有URLから入り直す前提にする
* ログインなしで再表示できることを優先する

### #21 共有URL MVP の手動スモークテストを行う

引き渡す内容は以下。

* 手動貼り付け → 取り込み → この内容で生成 → 再生成 → 採用 → 共有URLコピー → 共有URLから再表示、を通す
* リロード時に event / participant / generated_schedule が復元できることを確認する
* 採用済みの場合、操作カードが非表示になることを確認する
* core get 失敗時の表示も確認対象にする

## 7. 保留・後続で扱うもの

### 7.1 アクセスカウンター

共有URLのアクセスカウンターやアクセス分析は、ver0.1 ではアプリ内機能としては扱わない。

当面は Cloud Run / Hosting / Cloud Logging 等で確認できればよい。

将来的に、共有URLのアクセス数・参照元・端末・地域などを見る機能として別Issueで検討する。

### 7.2 取り込み結果の反映ルール

取り込み成功時に既存入力を上書きするか、空欄のみ反映するか、反映前プレビューを出すかは後続で検討する。

MVPでは、抽出結果専用の編集画面は作らず、入力フォームに反映する方針とする。

### 7.3 共有URLでの権限管理

ログインなし MVP のため、ownership は扱わない。

MVPでは、共有URLを知っている人が採用できる状態を許容する。

将来ログインを実装した後も、ログインなしで作成された対戦表については、ログインユーザーに紐づかない共有URLベースの対戦表として扱う。

### 7.4 共有URLの有効期限と再共有

share は event から独立した保存対象として扱い、有効期限を設けられる余地を残す。

ログインなしで作成された対戦表では、共有URLの有効期限が切れた場合、作成者本人でも再共有できない可能性がある。

ver0.1 ではこの制約を許容し、共有URLの再発行、期限延長、ログインユーザーとの紐づけは後続で検討する。
