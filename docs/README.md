# 📚 Lanske docs

このディレクトリは、Lanske web repository のドキュメント置き場です。

README はプロジェクト全体の入口、このファイルは `docs/` 配下の入口として扱います。

---

## ドキュメントの役割分担

### 公開ユーザー向け

Lanske を使う人が、機能・使い方・注意点を確認するためのドキュメントです。

- [ver0.1 使い方](usage-ver0.1.md)
- [ver0.1 既知の制限事項](known-limitations-ver0.1.md)

### 開発者向け

実装方針、開発ルール、リリース前確認を扱うドキュメントです。

- [Architecture](architecture.md)
- [Contributing Guide](contributing.md)
- [ver0.1 リリース前チェックリスト](release-checklist-ver0.1.md)

---

## 現時点の構成方針

ver0.1.1 時点では、ドキュメント数がまだ少ないため、`docs/` 直下に最小構成で置きます。

本格的なヘルプサイト化、FAQ、問い合わせ導線、ロードマップ、リリースノートなどは、必要になった段階で用途別に分けます。

想定する将来構成:

```text
docs/
├─ README.md                       # docs 入口
├─ usage-ver0.1.md                 # 公開ユーザー向けの使い方
├─ known-limitations-ver0.1.md     # 公開ユーザー向けの制限事項
├─ architecture.md                 # 開発者向け設計メモ
├─ contributing.md                 # 開発ルール・運用方針
├─ release-checklist-ver0.1.md     # リリース前確認
├─ support/                        # FAQ / 問い合わせ / ヘルプ候補
└─ release-notes/                  # リリースノート候補
```

今は空ディレクトリを先に作らず、必要なページが具体化した時点で追加します。

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
