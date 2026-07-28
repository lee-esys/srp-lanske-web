# 🏗️ Architecture

## 1. 概要

本システムは、ダブルス対戦表とチーム対戦表の作成・表示・保存・共有を行う Flutter Web アプリケーションである。

責務は、大きく以下へ分離する。

- `srp-lanske-web`
  - UI、入力、表示、共有URL、保存状態などを扱う公開アプリケーション
- `srp-lanske-core`
  - 対戦表生成と評価を扱う別リポジトリの core API

web 側には生成アルゴリズム本体を置かず、core API が返した生成結果を feature ごとに表示・保存できる形へ変換する。

---

## 2. 全体構成

```text
[ UI / Flutter Web ]
          ↓
[ feature application service ]
      ├──→ [ shared infrastructure ] ──→ [ srp-lanske-core API ]
      └──→ [ feature repository ] ─────→ [ Firestore / in-memory ]
```

生成処理と、web 側の保存・共有状態は別の責務として扱う。

- core API
  - 生成条件を受け取る
  - 対戦表を生成する
  - generated schedule snapshot を返す
- web
  - 入力情報を管理する
  - core API request を組み立てる
  - response を feature 固有の表示モデルへ変換する
  - event / view state、表示名、共有URLなどを保存する

---

## 3. ディレクトリ構成

```text
lib/
├─ app/
│  └─ config/                         # アプリ全体の環境設定
├─ features/
│  ├─ doubles_scheduler/
│  │  ├─ presentation/                # ダブルス用画面・widget・画面入力モデル
│  │  ├─ application/                 # request構築、ユースケース、repository interface
│  │  ├─ domain/                      # ダブルス用ドメインモデル
│  │  ├─ data/                        # Firestore / in-memory等のrepository実装
│  │  └─ infrastructure/              # ダブルス固有の外部接続
│  └─ team_scheduler/
│     ├─ presentation/                # チーム用画面・widget・画面入力モデル
│     ├─ application/                 # request構築、response変換、repository interface
│     ├─ domain/                      # チーム用ドメインモデル
│     └─ data/                        # Firestore / in-memory等のrepository実装
├─ shared/
│  ├─ infrastructure/                 # 複数featureから使う外部API client
│  └─ repositories/                   # repository実装のアプリ全体での選択・公開
└─ l10n/                              # Flutter l10n生成物と参照入口
```

feature 固有の処理は各 feature 配下へ置き、複数 feature に共通する外部接続のみ `shared/infrastructure` へ置く。

---

## 4. 各領域の責務

### 4.1 `app`

アプリ全体で共通する環境設定を扱う。

例:

- core API base URL
- Firestore repositoryを使うかどうか
- `dart-define` から受け取る実行環境設定

feature 固有の画面状態や生成条件は置かない。

### 4.2 `features/*/presentation`

役割:

- UI描画
- ユーザー入力の受付
- 画面状態の管理
- application serviceやrepositoryを呼び出す操作の起点

含むもの:

- pages
- widgets
- dialogs
- 画面入力用model

対戦表生成アルゴリズムや汎用HTTP通信処理は持たない。

### 4.3 `features/*/application`

役割:

- feature固有のユースケースを実行する
- UI入力からcore API requestを構築する
- core API responseをfeature固有のmodelへ変換する
- repository interfaceを定義する

例:

- `GeneratedScheduleService`
- `TeamGeneratedScheduleService`
- `EventRepository`
- `TeamScheduleRepository`

ダブルスとチームで異なる生成条件・request shape・response変換は、この層を中心に各 feature 側で扱う。

### 4.4 `features/*/domain`

役割:

- feature固有のデータ構造を定義する
- 保存・表示・変換で利用するmodelを保持する

生成アルゴリズム本体は持たない。

### 4.5 `features/*/data`

役割:

- applicationで定義したrepository interfaceの具体実装
- Firestoreへの保存・取得
- local確認用のin-memory実装
- 保存形式とdomain modelの変換

Firestoreとin-memoryの選択はアプリ設定に応じて行う。

### 4.6 `features/*/infrastructure`

feature固有の外部接続を扱う。

その接続が他のfeatureでも必要になった場合は、feature間で直接importせず、責務を確認した上で `shared/infrastructure` への移動を検討する。

### 4.7 `shared/infrastructure`

複数featureから利用する外部接続の共通処理を扱う。

現在は `GeneratedScheduleApiClient` を配置し、以下に責務を限定する。

- core API endpointへのHTTP request
- JSONのencode / decode
- HTTP statusとAPI errorの共通処理
- base URLからrequest URLを構築する処理

以下は持たない。

- doubles / team固有のrequest構築
- feature固有のdomain model
- feature固有のresponse変換
- UI状態

### 4.8 `shared/repositories`

アプリ全体で利用するrepository実装の選択と公開を行う。

現在は `AppConfig` を参照し、各featureのFirestore実装またはin-memory実装を選択する。

この領域は汎用domain層ではなく、アプリ全体の構成を組み立てるcomposition寄りの責務として扱う。

---

## 5. featureごとの責務

### 5.1 `doubles_scheduler`

- ダブルス用イベント・参加者入力
- ダブルス生成requestの構築
- ダブルス対戦表の表示
- 採用状態・共有URL・表示名の管理
- ダブルス用イベントの保存・復元

`GeneratedScheduleService` は、ダブルス用requestを構築して共通API clientへ渡す。

### 5.2 `team_scheduler`

- チーム用参加者・チーム条件入力
- チーム生成requestの構築
- team responseのdomain model変換
- チームカード・対戦表・スコア等の表示
- チーム用scheduleの保存・復元

`TeamGeneratedScheduleService` は、チーム固有のrequest構築とresponse変換を担当し、HTTP通信は共通API clientへ委譲する。

### 5.3 `shared`

- 複数featureで共通利用する外部API client
- アプリ全体で利用するrepository実装の選択

「共通に見える」という理由だけでfeature固有のmodelや処理を移さず、複数featureに共通する責務であることを確認して配置する。

---

## 6. Core（非公開）の責務

`srp-lanske-core` で管理する。

含むもの:

- ダブルス対戦表生成
- チーム分け・チーム対戦表生成
- 評価関数
- 制約判定
- 最適化ロジック
- generated schedule snapshotの保存・返却

非公開とする理由:

- アルゴリズムは本サービスの価値の中核であるため
- 営業秘密として保護するため

web はcoreの内部実装へ依存せず、公開されたAPI request / responseを通じて利用する。

---

## 7. データフロー

### 7.1 generated schedule生成

```text
ユーザー入力
  ↓
feature presentation
  ↓
feature application service
  ├─ feature固有requestを構築
  ↓
shared/infrastructure
  ├─ HTTP / JSON処理
  ↓
srp-lanske-core API
  ├─ 生成・保存・response返却
  ↓
feature application / domain
  ├─ feature固有modelへ変換
  ↓
UI表示
```

### 7.2 web側の保存・復元

```text
UI操作
  ↓
feature repository interface
  ↓
Firestoreまたはin-memory repository
  ↓
web側 event / schedule document
```

core generated schedule snapshotと、web側のevent / view stateは別に管理する。

---

## 8. 依存方針

### 8.1 feature固有処理をfeature内に保つ

- doubles用requestは `doubles_scheduler` で構築する
- team用request / response変換は `team_scheduler` で扱う
- 表示名、選択状態、画面固有modelは各featureに置く

### 8.2 feature間でinfrastructureを共有しない

`team_scheduler` がAPI接続のために `doubles_scheduler/infrastructure` をimportする、といった依存は作らない。

複数featureから利用する外部接続は、共通部分だけを `shared/infrastructure` へ配置する。

### 8.3 共通clientをfeature非依存に保つ

`GeneratedScheduleApiClient` は `Map<String, dynamic>` のJSON入出力と通信処理に集中し、doubles / teamのmodelへ依存しない。

これにより、新しいschedule typeを追加する場合も、共通通信処理を複製せず、feature側でrequest / response責務を追加できる。

### 8.4 sharedへの移動を過剰に行わない

単一featureでしか使わない処理は、そのfeature内へ置く。

複数featureから参照されるようになった時点で、共通化する責務と依存方向を確認してからsharedへの移動を判断する。

---

## 9. 現在の実装状態

- Flutter Webでdoubles / teamの画面を実装済み
- doubles / teamの双方が同じgenerated schedule API endpointを利用する
- 共通API clientは `shared/infrastructure/generated_schedule_api_client.dart` に配置済み
- doubles固有requestは `GeneratedScheduleService` で構築する
- team固有requestとresponse変換は `TeamGeneratedScheduleService` で扱う
- 対戦表生成アルゴリズムは `srp-lanske-core` へ分離済み
- web側のevent / schedule保存はFirestore repositoryで行える
- local確認用としてin-memory repositoryも維持する
- 採用状態はweb側のevent / view stateとして扱う

mock / in-memory実装は開発・確認用の代替経路であり、生成アルゴリズムをweb内へ置くためのものではない。

---

## 10. 今後の拡張

新しい競技・schedule typeを追加する場合は、原則としてfeature単位で追加する。

```text
features/
├─ doubles_scheduler/
├─ team_scheduler/
├─ round_robin/
├─ knockout/
└─ ...
```

追加時の方針:

- feature固有のUI・application・domain・dataをfeature内へ置く
- core APIの共通通信処理は `shared/infrastructure` を再利用する
- request / response shapeの差は各featureで吸収する
- feature間の直接依存が必要になった場合は、共通責務として切り出せるか先に検討する

---

## 11. 技術的判断メモ

- Flutter Webでの開発を前提とする
- GitHub Codespacesまたはlocal環境で開発する
- 対戦表生成backendとして `srp-lanske-core` APIを利用する
- web側の保存にはFirestoreを利用し、local確認用にin-memory実装を残す

### 11.1 core API URL の環境切り替え

web から接続するcore APIのbase URLは、`AppConfig.coreApiBaseUrl` から参照する。

`AppConfig.coreApiBaseUrl` はFlutterの `String.fromEnvironment` を使い、`LANSKE_CORE_API_BASE_URL` で指定する。

未指定の場合はlocal開発用として `http://localhost:8080` を使用する。

この設定値は、doubles / team双方のgenerated schedule API呼び出しで共通利用する。

ver0.1では、環境別設定ファイルやsecret管理を過度に増やさず、`dart-define` による明示的な切り替えを優先する。

### 11.2 共有URLと採用状態

共有URLは `publicId` を入口にする。

web側のevent / schedule documentに、現在表示・採用するcore generated schedule snapshotのIDを保存する。

最小schema方針:

```text
events/{publicId}
  event.publicId
  event.currentGeneratedScheduleId
  event.adoptedGeneratedScheduleId
  event.adoptedAt
  event.visibility
  event.visibleUntilRoundNo
  event.expiresAt
  event.revision
  event.createdAt
  event.updatedAt
```

`expiresAt` は作成から10日後を初期値として持つ。
ただし、ver0.1.xでは期限切れによる非表示処理はまだ行わない。

将来の試合カード進行状況・対戦成績は、event本体ではなく、試合カード単位のsubcollectionで扱う想定とする。

---

## 12. 設計思想

本システムは以下の思想に基づいて設計する。

> ランダムではなく、納得できる組み合わせを

この思想は以下に影響する。

- 評価関数の設計
- 制約条件の定義
- アルゴリズムの最適化方針
- UI上で生成条件と結果を確認しやすくする設計
