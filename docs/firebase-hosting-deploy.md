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

- ver0.1.3 では Flutter Web / Firebase Hosting の公開先を `lanske-srp` に切り替える。
- Android / iOS / macOS / Windows の Firebase app 設定整理は今回の対象外とする。
- `--platforms=web` で再生成した場合、Web 以外の既存 platform 設定が旧 project のまま残る場合があるが、Web deploy の確認対象は Web 用設定とする。

## Core API URL

公開用 build では、core API の base URL を `LANSKE_CORE_API_BASE_URL` で指定する。

現在の通常運用では、core API は以下の Cloud Run service を使う。

| 項目                | 値                 |
| ----------------- | ----------------- |
| Cloud Run project | `srp-lanske`      |
| Cloud Run service | `lanske-core-api` |
| region            | `asia-northeast1` |

core API URL は必要に応じて core 側の deploy docs / Cloud Run Console / `gcloud` で確認する。

```bash
gcloud run services describe lanske-core-api \
  --project srp-lanske \
  --region asia-northeast1 \
  --format="value(status.url)"
```

build 時は確認した URL を環境変数に入れる。

```bash
export LANSKE_CORE_API_BASE_URL="<srp-lanske の lanske-core-api URL>"
```

例:

```bash
echo "$LANSKE_CORE_API_BASE_URL"
```

注意:

- `LANSKE_CORE_API_BASE_URL` は build 時に `main.dart.js` へ埋め込まれる。
- build 後に環境変数だけ変更しても、既存の `build/web/main.dart.js` は変わらない。
- core Cloud Run 移行後は、旧 `jebra-lanske` の core URL が `main.dart.js` に残っていないことを確認する。

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

deploy 前に、`build/web` 内へ埋め込まれた core API URL を確認する。

```bash
grep -RahoE "https://lanske-core-api-[^\"' )]+" build/web | sort -u
```

期待値:

- `srp-lanske` 側の `lanske-core-api` URL が出る
- 旧 `jebra-lanske` 側の URL が出ない
- URL が複数出る場合は意図したものか確認する

旧 core URL が残っている場合は、`build/web` を削除して再 build する。

```bash
rm -rf build/web

flutter build web \
  --dart-define=LANSKE_CORE_API_BASE_URL="$LANSKE_CORE_API_BASE_URL" \
  --dart-define=LANSKE_EVENT_REPOSITORY=firestore

grep -RahoE "https://lanske-core-api-[^\"' )]+" build/web | sort -u
```

## Preview deploy

本番 live URL に出す前の確認は Firebase Hosting preview channel を使う。

```bash
npx firebase hosting:channel:deploy issue-123 --project lanske-srp
```

preview URL は一時的な公開 URL として発行される。

注意:

- preview channel は Hosting の確認用。
- preview URL でも、アプリが Firestore を使う場合は `lanske-srp` の Firestore に接続する。
- 本番 Firestore を触りたくない破壊系確認は、preview channel ではなく別 Firebase project を使う。
- preview URL から core API を呼び出す場合、core 側の `LANSKE_ALLOWED_ORIGINS` に preview URL の origin を追加する必要がある。

## Live deploy

preview channel で主要導線を確認したあと、本番 Hosting へ deploy する。

```bash
npx firebase deploy --only hosting --project lanske-srp
```

公開URL:

- [https://lanske-srp.web.app](https://lanske-srp.web.app)
- [https://lanske-srp.firebaseapp.com](https://lanske-srp.firebaseapp.com)

主導線としては `https://lanske-srp.web.app` を使う。

## Live Hosting の API URL 確認

deploy 後に、live Hosting の `main.dart.js` に埋め込まれた core API URL を確認する。

```bash
curl -sL "https://lanske-srp.web.app/main.dart.js?check=$(date +%s)" \
  | grep -aoE "https://lanske-core-api-[^\"' )]+" \
  | sort -u
```

期待値:

- `srp-lanske` 側の `lanske-core-api` URL が出る
- 旧 `jebra-lanske` 側の URL が出ない
- deploy 前に確認した `build/web` 内の URL と一致する

`lanske-srp.firebaseapp.com` 側も確認したい場合:

```bash
curl -sL "https://lanske-srp.firebaseapp.com/main.dart.js?check=$(date +%s)" \
  | grep -aoE "https://lanske-core-api-[^\"' )]+" \
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

deploy 後は以下も確認する。

```bash
curl -I "https://lanske-srp.web.app/team?check=$(date +%s)"
```

期待値:

- HTTP 200
- `/team` 直アクセスで画面が表示される
- 古い JS / 旧 API URL が使われていない

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

### API URL

- `build/web/main.dart.js` に現在の core API URL が埋め込まれている
- live Hosting の `main.dart.js` に現在の core API URL が埋め込まれている
- 旧 `jebra-lanske` core URL が残っていない

### common

- TOP が開ける
- 主要メニューが開ける
- hard reload / cache busting 後も表示できる
- `/team` など direct path が開ける

### doubles

- 対戦表を生成できる
- 採用 / 保存できる
- 共有URLを作成できる
- 共有URLから復元できる
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
