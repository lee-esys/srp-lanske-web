# 🎾 Lanske（らんすけ）

Lanske（らんすけ）は、テニスのダブルス向けに、対戦表を作成・共有するための Web アプリです。

参加者とコート数をもとに、出場回数・休憩・ペア・対戦相手の偏りをできるだけ抑えた対戦表を生成します。

> ランダムではなく、納得できる組み合わせを。

---

## 🌐 公開URL

https://lanske-srp.web.app

---

## 🚀 ver0.1 でできること

ver0.1 は、ログインなしで使える初回生成版です。

- テニスベアURLをメモとして保存できる
- テニスベアのイベント情報を貼り付けて取り込みできる
- event / participant 情報を確認・編集できる
- ダブルスの対戦表を生成できる
- 必要に応じて再生成できる
- 採用した対戦表を保存できる
- 共有URLをコピーできる
- 共有URLから対戦表を開き直せる
- リロードしても対戦表を復元できる
- TOP から保存済み対戦表一覧を開き、対戦表を復元できる

---

## ✅ 対応条件

ver0.1 では、以下の条件に対応しています。

| コート数 | 参加人数 |
|---|---|
| 1面 | 4〜7人 |
| 2面 | 8〜15人 |

生成される対戦数は、初回生成では 15 対戦固定です。

---

## 🧭 基本的な使い方

1. TOP から対戦表作成を開始する
2. 必要に応じてテニスベアURLを入力する
3. テニスベアのイベント情報を貼り付けて取り込む
4. event / participant 情報を確認・編集する
5. 対戦表を生成する
6. 必要に応じて再生成する
7. 使う対戦表を採用する
8. 共有URLをコピーする
9. 共有URLから開き直す、または参加者に共有する

詳しい使い方は以下を参照してください。

- [ver0.1 使い方](docs/usage-ver0.1.md)

---

## 🐻 テニスベア取り込みについて

ver0.1 のテニスベア取り込みは、貼り付け方式の MVP です。

Lanske は、テニスベアの募集・申込・決済・参加管理を代替するものではありません。

主催者本人が確認できる情報をもとに、対戦表作成・進行補助に使う想定です。
取り込み後は、event / participant 情報を確認・編集してから使用してください。

---

## 🔗 共有URLについて

Lanske は、共有URLを主導線とする MVP です。

採用した対戦表は共有URLから開き直せます。
また、ブラウザをリロードしても、保存済みの対戦表を復元できます。

ログインなしで使える一方、ver0.1 では細かい閲覧権限や編集権限はありません。
共有URLを知っている人は、対象の対戦表を開ける前提です。

---

## ⚠️ 既知の制限事項

ver0.1 には、以下の制限があります。

- ログインはありません
- 細かい ownership / 権限管理はありません
- 共有URLを知っている人は対戦表を開けます
- extend はありません
- 試合結果入力はありません
- 初回生成は 15 対戦固定です
- 対応条件は 1面4〜7人 / 2面8〜15人です
- テニスベアの自動取得はしません
- 取り込み結果は確認・編集してから使う必要があります

詳しくは以下を参照してください。

- [ver0.1 既知の制限事項](docs/known-limitations-ver0.1.md)

---

## 🧱 プロジェクト構成

```text
lib/
├─ app/                # アプリ全体設定
├─ features/
│  └─ doubles_scheduler/
└─ shared/             # 共通部品
```

---

## 💻 開発環境

本プロジェクトは GitHub Codespaces またはローカル環境で開発できます。

### 起動手順

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
```

---

## 🔌 core API URL の指定

web から接続する core API の base URL は、Flutter の `dart-define` で指定します。

未指定の場合は local 開発用として `http://localhost:8080` を使用します。

local core API に接続する場合:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 \
  --dart-define=LANSKE_CORE_API_BASE_URL=http://localhost:8080
```

公開用 core API に接続する場合:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 \
  --dart-define=LANSKE_CORE_API_BASE_URL=https://<core-api-url>
```

`<core-api-url>` には Cloud Run などの公開 core API URL を指定します。

---

## 📚 ドキュメント

ドキュメント全体の入口は以下です。

- [Docs index](docs/README.md)

主な公開ユーザー向けドキュメント:

- [ver0.1 使い方](docs/usage-ver0.1.md)
- [ver0.1 既知の制限事項](docs/known-limitations-ver0.1.md)
- [Support docs](docs/support/README.md)

主な開発者向けドキュメント:

- [Architecture](docs/architecture.md)
- [Contributing Guide](docs/contributing.md)
- [Firebase Hosting deploy memo](docs/firebase-hosting-deploy.md)
- [ver0.1 リリース前チェックリスト](docs/release-checklist-ver0.1.md)

---

## 🔐 設計方針

本プロジェクトでは以下を重視します。

* UI とロジックの分離
* 対戦表生成ロジックの分離
* 共有URLを中心にしたシンプルな利用導線
* 主催者が納得しやすい組み合わせ生成

アルゴリズム本体と core API は `srp-lanske-core` にて管理しています。

---

## 🚧 今後の予定

* ver0.1.1 docs / support pages 整理
* コート表示名の設定
* QRコード共有
* 参加者入力 UI の改善
* 対戦表一覧の整理
* シングルス / 固定ペア / チーム分け / トーナメント / ラウンドロビン対応の検討
* レーティング / 統計 / シード機能の検討
