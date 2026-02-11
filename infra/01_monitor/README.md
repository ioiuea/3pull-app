## 初期構築時の実行方法

初期構築時は `infra/README.md` の手順に従い、`infra/main.sh` を実行してください。  
`infra/main.sh` から `01_monitor` の `main.sh` が呼び出され、リソースが作成されます。

## 個別実行（更新用）

このフォルダの `main.sh` を直接実行することで、`01_monitor` を単体で更新できます。

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

### デプロイ

プロジェクトルートから infra/01_monitor フォルダへ移動します。

```bash
cd infra/01_monitor
```

#### デプロイの流れ

- `01_monitor`
  - **Azure Log Analytics Workspace** と **Azure Application Insights** を作成

#### デプロイコマンド（dry-run）

サブスクリプションスコープでデプロイコマンド（dry-run）を実行し出力を確認します。

```bash
./main.sh --what-if
```

#### デプロイコマンド

```bash
./main.sh
```
