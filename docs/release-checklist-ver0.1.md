# 🚦 Lanske ver0.1 リリース前チェックリスト

## 目的

`ver0.1` 公開前に、web / core / Firebase / Firestore / docs / 手動確認の抜け漏れを防ぐ。

このチェックリストは、完璧な運用手順書ではなく、`ver0.1` 公開可否を判断するための確認表として扱う。

---

## 1. リリース範囲の確認

### ver0.1 で含めるもの

- [ ] 共有URL前提の MVP として公開する
- [ ] ログインなしで利用できる
- [ ] テニスベアURL取り込みは、貼り付け取り込み方式として扱う
- [ ] event / participant の確認・編集ができる
- [ ] generate ができる
- [ ] 再生成ができる
- [ ] adopt ができる
- [ ] 共有URLをコピーできる
- [ ] 共有URL reopening ができる
- [ ] リロード復元ができる
- [ ] TOP から保存済み対戦表一覧を開き、復元できる

### ver0.1 で含めないもの

- [ ] OAuth / ログインは含めない
- [ ] ownership チェックは含めない
- [ ] extend は含めない
- [ ] cooldown は含めない
- [ ] テニスベアの自動スクレイピングは含めない
- [ ] 大規模な UI 改修は含めない
- [ ] generate アルゴリズムの抜本改善は含めない

---

## 2. core API 確認

### Cloud Run / API 環境

- [ ] 本番 core API URL を確認した
- [ ] Cloud Run service が起動している
- [ ] `/health` が正常応答する
- [ ] `/dbz` が正常応答する
- [ ] Cloud SQL 接続が正常である
- [ ] 本番環境変数が想定通りである
- [ ] 不要な debug / local 向け設定が本番に残っていない

### core API 動作

- [ ] `generate` が正常動作する
- [ ] `get` が正常動作する
- [ ] `adopt` が正常動作する
- [ ] 不正 request が想定通り error になる
- [ ] 未対応条件が想定通り error になる
- [ ] 存在しない generated_schedule_id が想定通り error になる

### CORS

- [ ] Firebase Hosting の公開 origin から core API を呼べる
- [ ] local 開発 origin の扱いを確認した
- [ ] Codespaces preview origin の扱いを確認した
- [ ] 不要な origin を許可しすぎていない
- [ ] 公開 web から generate / get / adopt 時に CORS error が出ない

---

## 3. web deploy 確認

### Firebase Hosting

- [ ] Firebase project を確認した
- [ ] Firebase Hosting target を確認した
- [ ] build / deploy command を確認した
- [ ] 公開 URL で TOP が表示される
- [ ] 共有URL形式の path で直アクセスできる
- [ ] 共有URL形式の path でリロードできる
- [ ] browser console に致命的な error が出ていない
- [ ] network error が出ていない

### dart-define / 設定

- [ ] `LANSKE_CORE_API_BASE_URL` が本番 core API を向いている
- [ ] event repository mode が本番想定になっている
- [ ] Firestore を使う場合のみ Firebase 初期化される
- [ ] local / Codespaces / production の設定差分を説明できる
- [ ] 本番 deploy 時に意図しない local URL が混入していない

---

## 4. Firebase / Firestore / security 確認

### Firestore 保存

- [ ] event 情報が保存される
- [ ] participant 表示情報が保存される
- [ ] share 情報が保存される
- [ ] import 情報が保存される
- [ ] `currentGeneratedScheduleId` が保存される
- [ ] `adoptedGeneratedScheduleId` が保存される
- [ ] generated_schedule 本体は web 側に保存せず、core 側 ID 参照のみである

### Firestore Rules

- [ ] ver0.1 用の Firestore Security Rules を確認した
- [ ] ログインなし MVP として許容する read / write 範囲を明文化した
- [ ] 共有URLを知っている人が復元できる設計である
- [ ] 想定外の全件読み取りができない、または ver0.1 の既知制限として明記した
- [ ] 将来 ownership / login で締める前提を記録した

### Firebase client config / secret scanning

- [ ] `firebase_options.dart` を repository 管理する方針で問題ないことを確認した
- [ ] Firebase `apiKey` が client config の範囲であることを確認した
- [ ] GitHub secret scanning alert の扱いを確認した
- [ ] Firebase API key restriction を確認した
- [ ] 必要に応じて App Check を ver0.1 必須 / 後回しに仕分けた

---

## 5. 本番スモークテスト

### 基本導線

- [ ] TOP を開ける
- [ ] テニスベアURL取り込みができる
- [ ] event 情報を確認・編集できる
- [ ] participant 情報を確認・編集できる
- [ ] generate できる
- [ ] 対戦表が表示される
- [ ] 再生成できる
- [ ] adopt できる
- [ ] 共有URLをコピーできる
- [ ] コピーした共有URLを別タブで開ける
- [ ] 共有URL reopening で対戦表を復元できる
- [ ] リロードしても復元できる
- [ ] TOP から対戦表一覧を開ける
- [ ] 対戦表一覧から保存済み対戦表を復元できる

### 全条件確認 generate

ver0.1 対応条件について、公開環境または本番相当環境で generate できることを確認する。

- [ ] 1面4人
- [ ] 1面5人
- [ ] 1面6人
- [ ] 1面7人
- [ ] 2面8人
- [ ] 2面9人
- [ ] 2面10人
- [ ] 2面11人
- [ ] 2面12人
- [ ] 2面13人
- [ ] 2面14人
- [ ] 2面15人

確認観点:

- [ ] generate が成功する
- [ ] 15対戦分表示される
- [ ] 休憩・出場の表示が破綻していない
- [ ] adopt できる
- [ ] 共有URL reopening で復元できる
- [ ] リロード復元できる
- [ ] 明らかに不自然な対戦表が出ていない
- [ ] generate 時間が実用上許容できる

---

## 6. performance / bundle 確認

### 計測環境

- [ ] Codespaces preview の初回表示時間を記録した
- [ ] local 実行時の初回表示時間を記録した
- [ ] Firebase Hosting 公開環境の初回表示時間を記録した
- [ ] Chrome DevTools Network で Disable cache ON / OFF の差を確認した
- [ ] Console error / warning を確認した

### 確認観点

- [ ] 公開環境の初回表示が実用上許容できる
- [ ] 公開環境で極端に大きい JS chunk がないか確認した
- [ ] icons / animated icons / form field / firestore 周辺の chunk size を確認した
- [ ] Codespaces 固有の遅さと、公開環境でも発生する遅さを分けて記録した
- [ ] performance 問題を ver0.1 リリースブロッカー / リリース後対応 / ver0.2 以降に仕分けた

### 現時点の気になる点

- [ ] Codespaces preview で約65秒程度かかるケースがある
- [ ] `text_form_field_row.dart.lib.js` が大きい
- [ ] `part_2.dart.lib.js` が大きい
- [ ] `icons.dart.lib.js` が大きい
- [ ] icon 周辺で重くなっている可能性がある
- [ ] 公開Hostingで同傾向が出るか確認する

---

## 7. docs / 表示文言 確認

### README

- [ ] README の概要が ver0.1 の状態に合っている
- [ ] 「開発初期段階」など古い表現を見直した
- [ ] 実装状況が現在の状態に合っている
- [ ] core API URL の指定方法が現在の運用に合っている
- [ ] Firebase / Firestore / Hosting について必要な説明がある

### 使い方

- [ ] ver0.1 でできることを書いた
- [ ] 対応条件を書いた
- [ ] 共有URLの使い方を書いた
- [ ] テニスベア取り込みの扱いを書いた
- [ ] URL共有時の注意を書いた
- [ ] ログインなし MVP であることを書いた

### 既知の制限事項

- [ ] 1面4〜7人 / 2面8〜15人のみ対応と書いた
- [ ] 初回生成15対戦固定と書いた
- [ ] extend なしと書いた
- [ ] login / ownership なしと書いた
- [ ] 共有URLを知っている人が閲覧できる前提を書いた
- [ ] テニスベア自動取得ではなく貼り付け取り込みであることを書いた
- [ ] performance 上の既知課題があれば書いた

---

## 8. base_schedule / generator 確認

- [ ] 対応条件ごとの generate が極端に遅くない
- [ ] 対応条件ごとの quality_score が極端に悪くない
- [ ] 手動検査で ver0.1 必須修正扱いになった問題が残っていない
- [ ] base_schedule 候補の事前生成・蓄積が必要か判断した
- [ ] 事前生成が必要な場合、ver0.1 リリース前必須か後回しか判断した
- [ ] job 化は ver0.1 必須ではないことを確認した

### DB 側データ確認

- [ ] `base_schedules.quality_score` が保存されている
- [ ] 対応条件ごとの `quality_score` に極端に悪い値がない

---

## 9. リリース判定

### リリース前必須

- [ ] 公開 web が表示できる
- [ ] 本番 core API に接続できる
- [ ] generate / get / adopt が本番相当環境で動く
- [ ] 共有URL reopening が動く
- [ ] リロード復元が動く
- [ ] Firestore rules / API key / secret scanning の扱いを説明できる
- [ ] 既知の制限事項が docs に書かれている

### リリース後対応でよいもの

- [ ] performance 改善
- [ ] UI 微修正
- [ ] docs の補足
- [ ] 代表条件以外の追加手動確認
- [ ] base_schedule 候補の拡充

### ver0.2 以降

- [ ] OAuth / login
- [ ] ownership
- [ ] extend
- [ ] cooldown
- [ ] App Check の本格導入
- [ ] Firestore rules の厳密化
- [ ] 利用分析
- [ ] generate アルゴリズム改善

---

## 10. 最終メモ

### 公開可否

- [ ] ver0.1 として公開してよい
- [ ] 条件付きで公開してよい
- [ ] 公開前に必須対応がある

### 残課題

| 種別 | 内容 | 対応Issue | 判定 |
|---|---|---|---|
| リリース前必須 |  |  |  |
| リリース後対応 |  |  |  |
| ver0.2以降 |  |  |  |
| 仕様として許容 |  |  |  |
