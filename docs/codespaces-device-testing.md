# Codespaces で開発中の Flutter Web を実機確認する

## 目的

GitHub Codespaces で起動した開発中の Flutter Web を、PC の別タブやスマートフォン、タブレットの実機ブラウザから確認するための手順をまとめる。

Firebase Hosting へ preview deploy する前でも、作業ブランチの表示やレスポンシブレイアウトを実機で確認できる。

## 前提

- `srp-lanske-web` の Codespace を起動している
- Flutter の依存関係を取得済みである
- 開発中のブランチへ checkout 済みである
- 実機からアクセスする間だけ、Codespaces の forwarded port を Public にできる

同じ Wi-Fi に接続している必要はない。Public にした forwarded URL へインターネット経由でアクセスする。

## Flutter Web を起動する

repository root で以下を実行する。

```bash
flutter pub get

flutter run -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 3000 \
  --dart-define=LANSKE_CORE_API_BASE_URL=https://<core-api-url> \
  --dart-define=LANSKE_EVENT_REPOSITORY=firestore
```

`<core-api-url>` には、確認に使用する公開 core API URL を指定する。

本番の core API と Firestore を指定した場合、開発中の画面から本番データを作成・更新する可能性がある。表示確認だけのつもりでも、保存操作を行う場合は接続先を確認する。

Flutter の起動ログと、Codespaces の `PORTS` タブに `3000` / `Flutter Web` が表示されることを確認する。

## forwarded port を公開する

1. Codespaces の `PORTS` タブを開く
2. `3000` / `Flutter Web` を右クリックする
3. `Port Visibility` を `Public` に変更する
4. `Forwarded Address` をコピーする

Public にした forwarded port は、URLを知っている人が認証なしでアクセスできる。実機確認中だけ Public にし、確認後は Private に戻すか forwarding を停止する。

Codespace を停止・再起動すると、Public にした port は Private に戻る。その場合は再度 Public に変更する。

## PC・スマートフォン・タブレットで確認する

コピーした forwarded URL を、確認したい端末のブラウザで開く。

主な確認項目:

- PC 幅で主要画面が表示される
- スマートフォン幅で表示領域やスクロールが崩れない
- タブレット幅で余白やレイアウトが不自然にならない
- メニュー、ダイアログ、SnackBar、キーボード表示が崩れない
- 作業対象の変更が意図どおり反映されている

初回表示は、Flutter Web の開発ビルド、Codespaces の port forwarding、端末側の通信環境により時間がかかる場合がある。

## Codespace 再開後

Codespace の停止後や timeout 後に再開した場合は、次を確認する。

1. Flutter Web を再起動する
2. `PORTS` タブに `3000` が表示されていることを確認する
3. 実機確認する場合は Port Visibility を再度 Public にする
4. `PORTS` タブから現在の Forwarded Address をコピーする

古いタブや保存済みURLではなく、現在の `PORTS` タブに表示されているURLを使用する。

## 404 の簡易切り分け

forwarded URL が 404 になる場合は、最初に Codespace 内の Flutter Web を確認する。

```bash
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/
```

### `200` の場合

Flutter Web は正常に応答しているため、Codespaces の port forwarding 側を確認する。

- Port Visibility を `Private` から `Public` へ設定し直す
- `Stop Forwarding Port` 後に `Add Port` で `3000` を追加し直す
- `PORTS` タブから現在の Forwarded Address をコピーし直す

### `200` 以外の場合

Flutter Web の起動状態を確認する。

```bash
ss -ltnp | grep ':3000'
```

process が存在しない場合や、別 port で起動している場合は、Flutter Web を `--web-port 3000` で起動し直す。

表示確認を始めるだけであれば、`gcloud login` や Application Default Credentials は必須ではない。Cloud Run の管理操作や、別途認証が必要な処理を行う場合に確認する。

## 確認終了後

- Port Visibility を Private に戻す、または forwarding を停止する
- Codespace を使い終えた場合は停止する
- 本番接続で作成した不要な確認データがないか確認する

## 関連

- [README](../README.md)
- [Firebase Hosting deploy memo](firebase-hosting-deploy.md)
- [GitHub Docs: Forwarding ports in your codespace](https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace)
- [GitHub Docs: Security in GitHub Codespaces](https://docs.github.com/en/codespaces/reference/security-in-github-codespaces)
