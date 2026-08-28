# Firestore provenance metadata

## 目的

Firestore に保存する対戦表データへ、作成元・最終更新元の Web 実行環境を記録する。

Firebase Hosting Preview や Codespaces、local から production Firestore を利用する場合でも、イベント名などの手作業の印ではなく保存データ自体から出自を確認できるようにする。

provenance は削除専用フラグではなく、調査・移行・テストデータ整理などに利用できる補助メタデータとして扱う。

## 保存形式

新規 document では次の形式を保存する。

```json
{
  "provenance": {
    "createdFrom": {
      "environment": "prod",
      "host": "lanske.jp",
      "firebaseProjectId": "lanske-srp",
      "appVersion": "0.2.0"
    },
    "lastWrittenFrom": {
      "environment": "prod",
      "host": "lanske.jp",
      "firebaseProjectId": "lanske-srp",
      "appVersion": "0.2.0"
    }
  }
}
```

- `createdFrom` は document の初回作成時に保存し、その後は変更しない。
- `lastWrittenFrom` は実際に Firestore write が発生したときに更新する。
- no-op 更新では `lastWrittenFrom` を変更しない。
- 既存 document に provenance がない場合、最初の更新時は `lastWrittenFrom` だけを追加する。作成元は推測して補完しない。

## 対象

- doubles: `events/{publicId}`
- team: `team_schedules/{shareId}`
- doubles / team 共通の `schedule_progress` document
- `schedule_progress/{generatedScheduleId}/matches/{matchKey}`

各 document 自身の作成元・最終更新元を記録する。
root document の `lastWrittenFrom` を subcollection write のたびに更新するための追加 write は行わない。

## environment

`LANSKE_APP_ENV` を build / run 時に明示する。

| 値 | 用途 |
| --- | --- |
| `prod` | production Hosting で利用する build |
| `preview` | Firebase Hosting Preview Channel で利用する build |
| `dev` | GitHub Codespaces 等の開発用ホスト |
| `local` | local PC 上の開発環境 |
| `unknown` | 未指定または不正な値 |

未指定値を host から推測して environment を決めない。
`LANSKE_APP_ENV` が未指定、または上記以外の値の場合は `unknown` とする。

Codespaces は `environment = dev` とし、具体的な Codespace は `host` で識別する。

## 各項目の取得元

### environment

`LANSKE_APP_ENV` の build-time / run-time `dart-define`。

### host

Web 実行時の `Uri.base.host`。
空の場合は `unknown` とする。
path / query / fragment は保存しない。

### firebaseProjectId

実際に write する `FirebaseFirestore` instance の Firebase app options から取得する。

そのため、将来 Firestore を prod / dev に分離した場合も、実際の保存先 project を記録できる。

### appVersion

`AppConfig.releaseVersion` を保存する。

## 起動・build 例

local:

```bash
flutter run -d chrome \
  --dart-define=LANSKE_APP_ENV=local \
  --dart-define=LANSKE_EVENT_REPOSITORY=firestore
```

Codespaces:

```bash
flutter run -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 3000 \
  --dart-define=LANSKE_APP_ENV=dev \
  --dart-define=LANSKE_EVENT_REPOSITORY=firestore
```

Firebase Hosting Preview 用 build:

```bash
flutter build web \
  --dart-define=LANSKE_APP_ENV=preview \
  --dart-define=LANSKE_EVENT_REPOSITORY=firestore \
  --dart-define=LANSKE_CORE_API_BASE_URL=https://api.lanske.jp
```

production 用 build:

```bash
flutter build web \
  --dart-define=LANSKE_APP_ENV=prod \
  --dart-define=LANSKE_EVENT_REPOSITORY=firestore \
  --dart-define=LANSKE_CORE_API_BASE_URL=https://api.lanske.jp
```

Preview と production で同じ `build/web` を使い回すと environment が同じ値のままになる。
Preview 確認後に live deploy する場合は、production 用に `LANSKE_APP_ENV=prod` で再 build してから deploy する。

## Firestore 接続先との関係

`environment` は Web をどの実行環境で動かしているか、`firebaseProjectId` はどの Firestore project へ保存したかを表す。

例:

```text
production Web
  environment = prod
  host = lanske.jp
  firebaseProjectId = lanske-srp

Firebase Hosting Preview
  environment = preview
  host = <preview>.web.app
  firebaseProjectId = lanske-srp

Codespaces
  environment = dev
  host = <codespace>-3000.app.github.dev
  firebaseProjectId = lanske-srp

local
  environment = local
  host = web.lanske.localhost
  firebaseProjectId = lanske-srp
```

Firestore 接続先を prod / dev に分離する対応は別 Issue とし、provenance 自体は接続先分離に依存しない。
