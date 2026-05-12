# 🎾 Lanske（らんすけ）

ダブルスの組み合わせを生成するアプリケーション。

---

## 🚀 概要

Lanske は、テニスのダブルス練習やイベントにおいて
「偏りの少ない組み合わせ」を生成するためのツールです。

現在は開発初期段階です。

---

## 💻 開発環境

本プロジェクトは **GitHub Codespaces** 上で開発可能です。

### 起動手順

1. GitHub 上で「Code」→「Codespaces」→「Create codespace」
2. 起動後、ターミナルで実行

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
````

3. ブラウザでプレビューを確認

---

## 🧱 プロジェクト構成

```text
lib/
├─ app/                # アプリ全体設定
├─ features/
│  └─ doubles_scheduler/
└─ shared/             # 共通部品
```

### core API URL の指定

web から接続する core API の base URL は、Flutter の `dart-define` で指定する。

未指定の場合は local 開発用として `http://localhost:8080` を使用する。

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

<core-api-url> には Cloud Run などの公開 core API URL を指定する。

---

## 📦 実装状況

* [x] プロジェクト構造
* [ ] ダブルス組み合わせ画面
* [ ] mock生成フロー
* [ ] アルゴリズム実装（core）

---

## 📚 ドキュメント

* [Architecture](docs/architecture.md)
* [Contributing Guide](docs/contributing.md)

---

## 🔐 設計方針

本プロジェクトでは以下を重視します：

* UIとロジックの分離
* アルゴリズムの分離（別リポジトリ）

アルゴリズム本体は `srp-lanske-core` にて管理予定。

---

## 🚧 今後の予定

* ダブルス組み合わせ生成ロジック
* 評価関数の設計
* UI改善
* Firebase連携

---

## 💡 コンセプト

> ランダムではなく、納得できる組み合わせを
