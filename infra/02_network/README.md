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
cd infra/02_network
```

サブスクリプションスコープでデプロイコマンド（dry-run）を実行し出力を確認します。  
`main.sh` がサブネットのアドレスを動的に計算し、一時パラメータを生成してからデプロイします。  
内部では `01_subnets → 02_firewall → 03_network_policy` の順に実行します。

```
./main.sh --what-if
```

`environmentName` / `systemName` / `location` / `vnetAddressPrefixes` / `subnets` は `infra/common.parameter.json` を読み込み、`currentDateTime` は Bicep 側で `utcNow()` を利用しているため、デプロイ時の `--parameters` 指定は不要です。  
サブネットの `addressPrefix` は `main.sh` 実行時に計算し、デプロイ時に一時パラメータとして渡します。

サブスクリプションスコープでデプロイコマンドを実行します。

```
./main.sh
```
