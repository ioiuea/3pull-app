## 初期構築時の実行方法

初期構築時は `infra/README.md` の手順に従い、`infra/main.sh` を実行してください。  
`infra/main.sh` から `02_network` の `main.sh` が呼び出され、リソースが作成されます。

## 個別実行（更新用）

このフォルダの `main.sh` を直接実行することで、`02_network` を単体で更新できます。  
**前提要件:** `01_monitor` を先に実行済みで、そこで作成されるリソースが存在していること。

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

プロジェクトルートから infra/02_network フォルダへ移動します。

```bash
cd infra/02_network
```

#### デプロイの流れ

- `02_network`
  - **Azure Virtual Network (VNet)** / **Subnets** / **User Defined Route (UDR)** / **Network Security Group (NSG)** を作成してサブネットと紐づけ

`infra/common.parameter.json` を読み込み、実行時にサブネットの `addressPrefix` などを動的に計算しパラメータとして生成しデプロイを行います。

#### デプロイコマンド（dry-run）

サブスクリプションスコープでデプロイコマンド（dry-run）を実行し出力を確認します。

```bash
./main.sh --what-if
```

#### デプロイコマンド

```bash
./main.sh
```
