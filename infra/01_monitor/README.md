# Azureログイン

Azure CLIを利用してAzureへログインします。

```
az login
```

# 操作対象のサブスクリプションIDを設定

操作対象のサブスクリプションを設定します。

```
az account set --subscription {SubscriptionId}
```

現在選択中のサブスクリプション確認します。

```
az account show
```

# デプロイ

プロジェクトルートからモジュールのフォルダへ移動します。

```
cd infra/01_monitor
```

サブスクリプションスコープでデプロイコマンド（dry-run）を実行し出力を確認します。

```
./main.sh --what-if
```

`environmentName` / `systemName` / `location` は `infra/common.parameter.json` を読み込み、`currentDateTime` は Bicep 側で `utcNow()` を利用しているため、デプロイ時の `--parameters` 指定は不要です。  
`main.sh` が `location` を検証し、Bicep を実行します。

サブスクリプションスコープでデプロイコマンドを実行します。

```
./main.sh
```
