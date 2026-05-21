# 🤝 Contributing Guide

このドキュメントは、Lanske web repository の開発ルール・運用方針の入口です。

詳細な設計方針は [Architecture](architecture.md)、リリース前確認は [ver0.1 リリース前チェックリスト](release-checklist-ver0.1.md) を参照します。

docs 全体の入口は [Docs index](README.md) です。

---

## 🧭 基本方針

- 小さく作る
- 構造を守る
- アルゴリズムとアプリを分離する
- 再現性のある実装を意識する
- 公開ユーザー向け docs と開発者向け docs を混ぜすぎない

---

## 🌿 ブランチ戦略

### main

- 安定ブランチ
- 直接コミット禁止
- Pull Request 経由でのみ更新

---

### 作業ブランチ

- 1ブランチ = 1目的
- Issue 単位で作成する
- 作業内容が分かる prefix を使う

例:

```text
feat/1-project-structure
feat/2-page-skeleton
feat/3-mock-generation-flow
docs/5-reorganize-docs
refactor/63-split-event-setup-ui
```

実装作業は `feat/`、docs 整理は `docs/`、リファクタリングは `refactor/` など、作業内容に合わせて選ぶ。

---

### Issueとクローズのルール

- 親Issue（ブランチ単位）は、`main` への merge 時に `closes #issue` とする
- 子Issue / 関連Issue（小タスク単位）は、該当コミットで `closes #issue` としてよい
- 作業途中のコミットでは `refs #issue` を使用する

例:

```text
🔌 feat: add scheduler controller closes #7 refs #3
🖼️ feat: add result view refs #3
```

最終マージ時:

```text
🔌 feat: add mock schedule generation flow closes #3
```

---

## 🔀 開発フロー

1. `main` を最新化
2. 作業ブランチを作成
3. 実装または docs 更新
4. コミット
5. Push
6. Pull Request 作成
7. 動作確認
8. `Squash and merge`
9. ブランチ削除

---

## ✍️ コミットメッセージ規約

### フォーマット

```text
<emoji> <type>: <summary> [refs #issue]
```

または

```text
<emoji> <type>: <summary> closes #issue
```

---

### 例

```text
🏗️ chore: initialize project structure refs #1
🖼️ feat: add doubles scheduler page skeleton refs #2
🔌 feat: add mock schedule generation flow refs #3
♻️ refactor: split scheduler form widget refs #5
🐛 fix: handle invalid player count input refs #8
📝 docs: update architecture for core separation refs #10
```

---

### type 一覧

- `feat` : 機能追加
- `fix` : バグ修正
- `refactor` : リファクタリング
- `chore` : 構造・設定・雑務
- `docs` : ドキュメント
- `test` : テスト
- `remove` : 削除

---

### 絵文字一覧

```text
🏗️ chore:
✨ feat:
🖼️ feat:
🔌 feat:
🐛 fix:
♻️ refactor:
📝 docs:
✅ test:
🔥 remove:
🚚 chore:
🔒 chore:
```

---

## 🧱 アーキテクチャ方針

- presentation / application / domain / infrastructure を分離
- UIとロジックを分離
- アルゴリズムは core 側へ切り出す

詳しくは [Architecture](architecture.md) を参照する。

---

## 🔐 アルゴリズムの扱い

- 本リポジトリにはアルゴリズム本体を含めない
- repository 経由で接続する
- core リポジトリで管理する

---

## 🧪 実装ルール

- controller にロジックを書かない
- UseCase に責務を寄せる
- mock 実装でも repository を通す
- 1コミット1目的を意識する

---

## ✅ PR 前確認

web 側の実装・docs 更新後は、必要に応じて以下を確認する。

```bash
dart format lib/
flutter analyze
flutter test
```

docs のみの変更では、実装に影響しないことを確認したうえで、実行不要と判断してよい。
その場合も、PR 本文や作業メモで「docs のみの変更のため未実行」と明記する。

---

## 📌 注意事項

- 機密情報を含めない
- `.env` や認証情報はコミットしない
- `.gitignore` を遵守する
- 公開ユーザー向け docs に、内部運用や未確定の詳細を混ぜすぎない
- 一時的な詳細検討メモは、必要に応じて worklog 側に置く

---

## 🚧 今後の拡張

- round_robin
- knockout
- score

機能単位で拡張していく

---

## 💡 判断基準

実装に迷った場合は、以下の観点を優先する:

> ランダムではなく、納得できる組み合わせを
