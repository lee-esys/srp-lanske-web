# Firebase Hosting deploy memo

## Requirements

- Node.js 20 or later
- Firebase CLI

Codespaces で `firebase-tools` が Node.js version error を出す場合は、Node.js 22 へ更新する。

```bash
sudo npm install -g n
sudo n 22
hash -r

node --version
npm --version
````

## Build

```bash
flutter build web \
  --dart-define=LANSKE_CORE_API_BASE_URL=<Cloud Run core API URL> \
  --dart-define=LANSKE_EVENT_REPOSITORY=firestore
```

## Deploy

```bash
npx firebase deploy --only hosting --project srp-lanske-web-dev
```
