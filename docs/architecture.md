# 🏗️ Architecture

## 1. 概要

本システムは、ダブルス組み合わせ生成アプリケーションである。

構成は以下の2層に分離する：

- アプリケーション層（公開）
- スケジューリングアルゴリズム層（非公開）

---

## 2. 全体構成

```
[ UI / Flutter App ]
        ↓
[ Application Layer ]
        ↓
[ Repository Interface ]
        ↓
[ Algorithm Core（別リポジトリ） ]
```

---

## 3. レイヤー構成（アプリ側）

```
lib/
├─ app/
├─ features/
│  └─ doubles_scheduler/
│     ├─ presentation/
│     ├─ application/
│     ├─ domain/
│     └─ infrastructure/
└─ shared/
```

---

## 4. 各レイヤーの責務

### 4.1 presentation

役割：

* UI描画
* ユーザー入力の受付
* 状態の表示

含むもの：

* pages
* widgets
* controllers

責務外：

* アルゴリズムロジック
* 複雑なビジネスルール

---

### 4.2 application

役割：

* ユースケースの実行
* 処理の流れの制御

例：

* generate_doubles_schedule

責務：

* request生成
* repository呼び出し
* result返却

責務外：

* スケジューリングの詳細ロジック

---

### 4.3 domain

役割：

* データ構造の定義

含むもの：

* request
* result
* モデル

注意：

* ロジックは極力持たない
* 計算処理はcore側へ寄せる

---

### 4.4 infrastructure

役割：

* 外部との接続

例：

* API呼び出し
* mock実装

責務：

* repositoryの具体実装

---

## 5. Core（非公開）の責務

別リポジトリ（srp-lanske-core）で管理する。

含むもの：

* 組み合わせ生成
* 評価関数
* 制約判定
* 最適化ロジック

非公開とする理由：

* アルゴリズムは本サービスの価値の中核であるため
* 営業秘密として保護する

---

## 6. データフロー

```
UI入力
 ↓
Controller
 ↓
UseCase
 ↓
Repository
 ↓
Core（生成）
 ↓
Result
 ↓
UI表示
```

---

## 7. 設計方針

### 7.1 関心の分離

* UIとロジックを分離する
* ロジックとアルゴリズムを分離する

---

### 7.2 依存方向

依存は常に内側へ向かう：

```
presentation → application → domain
presentation → infrastructure
```

coreには直接依存しない（interface経由）

---

### 7.3 アルゴリズムの隔離

* アプリ側にアルゴリズムを持たせない
* repository経由でのみ呼び出す

---

## 8. 現在の実装状態

* mock repository による動作確認
* アルゴリズムは暫定的にアプリ内に存在（後に分離予定）

```id="v1m8zx"
TODO: move algorithm to srp-lanske-core
```

---

## 9. 今後の拡張

予定機能：

* round_robin
* knockout
* score

拡張方法：

```
features/
├─ doubles_scheduler/
├─ round_robin/
├─ knockout/
└─ score/
```

---

## 10. 技術的判断メモ

* Flutter Webでの開発を前提
* Codespacesでの開発を想定
* 将来的にバックエンド化（Cloud Functions等）

### 10.1 core API URL の環境切り替え

web から接続する core API の base URL は、`AppConfig.coreApiBaseUrl` から参照する。

`AppConfig.coreApiBaseUrl` は Flutter の `String.fromEnvironment` を使い、`LANSKE_CORE_API_BASE_URL` で指定する。

未指定の場合は local 開発用として `http://localhost:8080` を使用する。

この設定値は以下の core API 呼び出しで共通利用する。

- generate
- get

採用状態は、web 側の event / view state として扱う。
backend 側の generated schedule snapshot は、通常の採用操作では更新しない。

ver0.1 では、環境別設定ファイルや secret 管理の本格化は行わず、`dart-define` による明示的な切り替えを優先する。

### 10.2 共有URLと採用状態

共有URLは `publicId` を入口にする。
web 側の `events/{publicId}` 相当の document に、現在表示・採用する backend 側 generated schedule snapshot の ID を保存する。

最小 schema 方針：

```txt
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
ただし、ver0.1.x では期限切れによる非表示処理はまだ行わない。

将来の試合カード進行状況・対戦成績は、event 本体ではなく、試合カード単位の subcollection で扱う想定とする。
`events/{publicId}/matchCards/{roundNo}_{courtNo}` のような形を候補にし、document が存在しない場合は既定で「試合前」とみなせるようにする。

---

## 11. 設計思想

本システムは以下の思想に基づいて設計する：

> ランダムではなく、納得できる組み合わせを

この思想は以下に影響する：

- 評価関数の設計
- 制約条件の定義
- アルゴリズムの最適化方針
