# Firebase Hosting deploy memo

## Requirements

- Node.js 20 or later
- Firebase CLI
- FlutterFire CLI

Codespaces で `firebase-tools` が Node.js version error を出す場合は、Node.js 22 へ更新する。

```bash
sudo npm install -g n
sudo n 22
hash -r

node --version
npm --version
```

## Firebase projects

ver0.1.3 以降、公開用の本命 Firebase project は `lanske-srp` とする。

| project              | 役割                                                         |
| -------------------- | ---------------------------------------------------------- |
| `lanske-srp`         | 本番公開用。README / docs / support / TennisBear 掲載リンクなどの主参照先    |
| `srp-lanske-web-dev` | 旧 dev / 旧公開確認用。通常の確認は `lanske-srp` の preview channel を優先する |

`.firebaserc` では以下の alias を使う。

| alias     | project              |
| --------- | -------------------- |
| `default` | `lanske-srp`         |
| `prod`    | `lanske-srp`         |
| `dev`     | `srp-lanske-web-dev` |

## Production URLs

利用者向けの正式 Web URL は以下とする。

```text
https://lanske.jp
```

`www` は独立した公開先にはせず、Firebase Hosting の custom domain redirect を使って apex へ転送する。

```text
https://www.lanske.jp
  -> https://lanske.jp
```

Firebase Hosting の標準 URL は継続して利用できる状態を維持する。

```text
https://lanske-srp.web.app
https://lanske-srp.firebaseapp.com
```

正式 API URL は以下とする。

```text
https://api.lanske.jp
```

## Firebase config

Flutter Web の Firebase config は `flutterfire configure` で生成する。

```bash
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"

flutterfire configure \
  --project=lanske-srp \
  --platforms=web \
  --out=lib/firebase_options.dart
```

`firebase_options.dart` の Web 用設定で、少なくとも `projectId` が `lanske-srp` になっていることを確認する。

```bash
grep -n "projectId\|authDomain\|storageBucket\|appId\|messagingSenderId" lib/firebase_options.dart
```

補足:

- ver0.1.3 では Flutter Web / Firebase Hosting の公開先を `lanske-srp` に切り替えた。
- Android / iOS / macOS / Windows の Firebase app 設定整理は Web deploy の確認対象外とする。
- `--platforms=web` で再生成した場合、Web 以外の既存 platform 設定が旧 project のまま残る場合があるが、Web deploy の確認対象は Web 用設定とする。
- `authDomain` などに `*.firebaseapp.com` が残ることは Firebase client config として正常であり、custom domain 化を理由に置換しない。

## Core API URL

production build では、core API の base URL に正式 URL を指定する。

```bash
export LANSKE_CORE_API_BASE_URL="https://api.lanske.jp"
```

確認:

```bash
echo "$LANSKE_CORE_API_BASE_URL"
```

注意:

- `LANSKE_CORE_API_BASE_URL` は build 時に `main.dart.js` へ埋め込まれる。
- build 後に環境変数だけ変更しても、既存の `build/web/main.dart.js` は変わらない。
- production Web では Cloud Run の `run.app` URL を直接指定せず、`https://api.lanske.jp` を使用する。
- `https://lanske.jp` から production API を利用するには、core 側の production CORS allowlist に `https://lanske.jp` が exact origin として必要。
- `www.lanske.jp` は `lanske.jp` への redirect 専用で、通常は API request origin にならないため CORS allowlist へ追加しない。

## Build

公開用 build では、core API の base URL と Firestore repository mode を `dart-define` で指定する。

古い build 成果物を deploy しないため、必要に応じて `build/web` を削除してから build する。

```bash
rm -rf build/web

flutter build web \
  --dart-define=LANSKE_CORE_API_BASE_URL="$LANSKE_CORE_API_BASE_URL" \
  --dart-define=LANSKE_EVENT_REPOSITORY=firestore
```

## Build artifact の API URL 確認

deploy 前に、`build/web/main.dart.js` が正式 API URL を参照していることを確認する。

```bash
grep -ao 'https://api\.lanske\.jp' build/web/main.dart.js | sort -u
```

期待値:

```text
https://api.lanske.jp
```

旧 Cloud Run URL 等が残っていないことも確認する。

```bash
grep -aoE 'https://[^"[:space:]]+' build/web/main.dart.js \
  | grep -E 'run\.app|lanske-core-api|jebra-lanske' \
  | sort -u
```

期待値は出力なし。

正式 API URL が出ない、または旧 URL が残っている場合は `build/web` を削除して再 build する。

## Preview deploy

本番 live URL に出す前の確認は Firebase Hosting preview channel を使う。

Issue 単位の一時 preview の例:

```bash
npx firebase hosting:channel:deploy issue-123 --project lanske-srp
```

Core API との接続確認など、定期的に再利用する preview は固定 channel `core-api-preview` を使う。

```bash
npx firebase hosting:channel:deploy core-api-preview \
  --expires 30d \
  --project lanske-srp
```

注意:

- preview channel は Hosting の確認用。
- preview URL でも、アプリが Firestore を使う場合は `lanske-srp` の Firestore に接続する。
- 本番 Firestore を触りたくない破壊系確認は、preview channel ではなく別 Firebase project を使う。
- preview URL から core API を呼び出す場合、core 側の `LANSKE_ALLOWED_ORIGINS` にその preview URL の exact origin を追加する必要がある。
- preview channel には有効期限がある。固定 channel を継続利用する場合は期限切れ前に同じ channel 名へ再 deploy する。
- 同じ fixed channel を継続利用している間は URL を CORS allowlist の exact origin として扱いやすいが、削除・再作成等で URL が変わった場合は allowlist も更新する。

## Live deploy

preview channel で主要導線を確認したあと、本番 Hosting へ deploy する。

```bash
npx firebase deploy --only hosting --project lanske-srp
```

公開先:

- 正式 URL: [https://lanske.jp](https://lanske.jp)
- Firebase Hosting 標準 URL: [https://lanske-srp.web.app](https://lanske-srp.web.app)
- Firebase Hosting 標準 URL: [https://lanske-srp.firebaseapp.com](https://lanske-srp.firebaseapp.com)
- `https://www.lanske.jp` は `https://lanske.jp` へ redirect

利用者向けの正式 URL は `https://lanske.jp` とするが、Firebase Hosting の標準 URL は無効化せず継続して利用できる状態を維持する。

## Custom domain / DNS

Firebase Hosting の custom domain として以下を設定する。

```text
lanske.jp
www.lanske.jp -> lanske.jp redirect
```

2026-08-13 の設定時に Firebase Console から指定された DNS record は以下。

| 用途 | host | type | value |
| ---- | ---- | ---- | ----- |
| apex Hosting | `lanske.jp` | A | `199.36.158.100` |
| apex verification | `lanske.jp` | TXT | `hosting-site=lanske-srp` |
| www Hosting / redirect | `www.lanske.jp` | CNAME | `lanske-srp.web.app` |

DNS 設定時の注意:

- 上記は実績値として記録する。
- custom domain を再設定する場合は、必ず Firebase Console にその時点で表示される値を正本とし、過去の値を決め打ちしない。
- `api.lanske.jp` は core API 用の独立した DNS record のため、Web custom domain 設定では変更しない。
- Firebase Console で domain verification と SSL certificate の発行・接続完了を確認する。
- 証明書発行前に HTTPS アクセスすると警告が出る場合があるため、接続済みになってからブラウザで再確認する。

確認例:

```bash
nslookup -type=A lanske.jp 8.8.8.8
nslookup -type=TXT lanske.jp 8.8.8.8
nslookup -type=CNAME www.lanske.jp 8.8.8.8
nslookup -type=A api.lanske.jp 8.8.8.8
```

## Live Hosting の API URL 確認

deploy 後に、正式 URL で配信されている `main.dart.js` が正式 API URL を参照していることを確認する。

```bash
curl -sL "https://lanske.jp/main.dart.js?check=$(date +%s)" \
  | grep -ao 'https://api\.lanske\.jp' \
  | sort -u
```

期待値:

```text
https://api.lanske.jp
```

旧 Cloud Run URL 等が残っていないことも確認する。

```bash
curl -sL "https://lanske.jp/main.dart.js?check=$(date +%s)" \
  | grep -aoE 'https://[^"[:space:]]+' \
  | grep -E 'run\.app|lanske-core-api|jebra-lanske' \
  | sort -u
```

期待値は出力なし。

Firebase Hosting 標準 URL 側も必要に応じて同様に確認できる。

```bash
curl -sL "https://lanske-srp.web.app/main.dart.js?check=$(date +%s)" \
  | grep -ao 'https://api\.lanske\.jp' \
  | sort -u
```

## Flutter Web / service worker / browser cache の注意

Flutter Web / Firebase Hosting / browser cache の影響で、deploy 後すぐに古い JS が見える場合がある。

確認時は以下を優先する。

- `curl` で `main.dart.js?check=$(date +%s)` のように cache busting して確認する
- ブラウザでは hard reload を使う
- 必要に応じて DevTools で Disable cache を有効にする
- service worker の影響が疑わしい場合は、Application タブから unregister / storage clear を行う
- 別ブラウザまたはシークレットウィンドウでも確認する

API URL の正否は、画面表示だけで判断せず、live Hosting の `main.dart.js` を直接確認する。

## `/team` 直アクセス確認

Firebase Hosting は SPA として `/team` などの direct path を `index.html` に rewrite する。

deploy 後は正式 URL でも確認する。

```bash
curl -I "https://lanske.jp/team?check=$(date +%s)"
```

期待値:

- HTTP 200
- `/team` 直アクセスで画面が表示される
- 古い JS / 旧 API URL が使われていない

Firebase Hosting 標準 URL を使った確認も引き続き可能。

## Firestore Rules deploy

Firestore Security Rules は `firestore.rules` で管理する。

Rules の deploy は Hosting deploy とは別に行う。

```bash
npx firebase deploy --only firestore:rules --project lanske-srp
```

deploy 前に以下を確認する。

- `firestore.rules` に必要な collection の rule が含まれている
- `firebase.json` に Firestore Rules 設定が含まれている
- 期限付きの全許可 rule に依存していない
- 不要な `delete` 許可を追加していない

現在クライアントから利用する主な collection は以下。

| collection       | 用途                      | client write    |
| ---------------- | ----------------------- | --------------- |
| `events`         | doubles schedule の保存・復元 | create / update |
| `team_schedules` | team schedule の保存・復元・編集 | create / update |
| `core_*`         | core 由来の既存データ参照         | なし              |

`core_*` collection は client から read のみ許可し、create / update / delete は許可しない。

deploy 後は以下を軽く確認する。

- doubles schedule を保存できる
- doubles schedule を共有URLから復元できる
- team schedule を保存できる
- team schedule を共有URLから復元できる
- team schedule の表示名編集を保存できる
- team schedule のスコア更新を保存できる
- Firebase Console の Rules が repo の `firestore.rules` と一致している

## Firestore data migration policy

ver0.1.3 の `lanske-srp` 切り替えでは、旧 `srp-lanske-web-dev` の Firestore データは移行しない。

理由:

- 現時点では利用者が少ない
- 対戦表データは TTL 前提で、消えても致命的ではない
- Firestore export / import は Cloud Storage や課金まわりの作業が発生する
- 将来的に必要になった場合は、RDB / core 側から復旧する仕組みを別 Issue で検討する

そのため、旧 project の Firestore に保存された既存対戦表は、新しい `lanske-srp` の公開URLでは復元しない。

## Post-deploy checks

live deploy 後は以下を確認する。

### domain / API URL

- `https://lanske.jp` が SSL warning なしで開ける
- `https://www.lanske.jp` が `https://lanske.jp` へ redirect される
- `build/web/main.dart.js` に `https://api.lanske.jp` が埋め込まれている
- `https://lanske.jp/main.dart.js` に `https://api.lanske.jp` が埋め込まれている
- `run.app` / 旧 core URL が production build / live Hosting に残っていない
- `https://lanske.jp` から production API を利用できる
- local Web から production API を利用できない状態を維持している

### common

- TOP が開ける
- 主要メニューが開ける
- hard reload / cache busting 後も表示できる
- `/team` など direct path が開ける
- Firebase Hosting 標準 URL でも必要な確認を継続できる

### doubles

- 対戦表を生成できる
- 採用 / 保存できる
- 共有URLを作成できる
- 共有URLから復元できる
- リロード後も復元できる
- QRコードを表示できる
- 対戦表一覧を開ける

### team

- `/team` が開ける
- team schedule を生成できる
- team schedule を保存できる
- 共有URLから復元できる
- 表示名編集を保存できる
- スコア更新を保存できる

### boccia

- boccia 用の team schedule 導線が開ける
- 生成 / 保存 / 復元の主要導線が動く
- スコア更新が保存される

### support

- support ページを開ける
- `/support/index.html` が開ける
- `/support/` が開ける
- support ページから feedback form を開ける
