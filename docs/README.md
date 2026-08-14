# 📚 Lanske docs

このディレクトリは、Lanske web repository のドキュメント置き場です。

README はプロジェクト全体の入口、このファイルは `docs/` 配下の入口として扱います。

---

## ドキュメントの役割分担

### 公開ユーザー向け

Lanske を使う人が、機能・使い方・注意点を確認するためのドキュメントです。

- [ver0.1 使い方](usage-ver0.1.md)
- [ver0.1 既知の制限事項](known-limitations-ver0.1.md)
- [Support docs](support/README.md)
  - [問い合わせ / 要望受付](support/feedback.md)

### 開発者向け

実装方針、開発ルール、リリース前確認を扱うドキュメントです。

- [Architecture](architecture.md)
- [UI ナビゲーション・操作配置方針](ui-navigation-guidelines.md)
- [ダブルス試合結果入力の保存継続と未保存制御](doubles-match-result-editing.md)
- [Contributing Guide](contributing.md)
- [Codespaces での実機表示確認](codespaces-device-testing.md)
- [Firebase Hosting deploy memo](firebase-hosting-deploy.md)
- [ver0.1 リリース前チェックリスト](release-checklist-ver0.1.md)

---

## 現時点の構成方針

ver0.1.1 時点では、ドキュメント数がまだ少ないため、`docs/` 直下と `docs/support/` に最小構成で置きます。

本格的なヘルプサイト化、FAQ、ロードマップ、リリースノートなどは、必要になった段階で用途別に分けます。

問い合わせ / 要望受付は、まず Google Forms などの外部フォームを使い、アプリ側はリンク導線に留める方針です。

想定する将来構成:

```text
docs/
├─ README.md                       # docs 入口
├─ usage-ver0.1.md                 # 公開ユーザー向けの使い方
├─ known-limitations-ver0.1.md     # 公開ユーザー向けの制限事項
├─ architecture.md                 # 開発者向け設計メモ
├─ ui-navigation-guidelines.md     # AppBar / Drawer / 操作配置方針
├─ doubles-match-result-editing.md # 試合結果入力の保存継続・未保存制御
├─ contributing.md                 # 開発ルール・運用方針
├─ codespaces-device-testing.md    # Codespaces での実機表示確認
├─ firebase-hosting-deploy.md      # Firebase Hosting deploy memo
├─ release-checklist-ver0.1.md     # リリース前確認
├─ support/
│  ├─ README.md                    # support 系 docs 入口
│  ├─ feedback.md                  # 問い合わせ / 要望受付
│  ├─ faq.md                       # FAQ 候補
│  └─ help.md                      # スクショ付きヘルプ候補
└─ release-notes/                  # リリースノート候補
```

空ファイルや空ディレクトリは先に作らず、必要なページが具体化した時点で追加します。

---

## 追加・整理するときの判断基準

新しいドキュメントを追加するときは、まず次のどれに該当するかを確認します。

- 公開ユーザー向け: 使い方、注意点、FAQ、問い合わせ案内
- 開発者向け: 設計、実装方針、開発フロー、PR 前確認
- リリース/運用向け: リリースチェック、既知の不具合、更新履歴
- 作業メモ向け: 一時的な検討、詳細調査、対応済みメモ

一時的な詳細検討メモは、必要に応じて web repository ではなく worklog 側に置きます。

---

## 関連

- [README](../README.md)
