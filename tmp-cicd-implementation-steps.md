# 改訂版 実装ステップ（推奨順）

1. Azure 基盤の先行準備（最低限）
- ACR を先に作成
- dev/stg/prod のリソースグループ・命名規約を確定

2. Dockerfile 作成
- web.Dockerfile
- api.Dockerfile
- ローカルで build 成功まで確認

3. CI を PR 専用に固定
- ci.yml を pull_request（develop/staging/main）中心へ整理
- 実行コマンドは make all-ci に統一

4. Branch Protection 設定
- develop/staging/main で CI 必須化
- 失敗時マージ禁止、直 push 制限

5. GitHub Environments + Azure OIDC
- dev/stg/prod Environment 作成
- Azure Federated Credential を設定（az login をOIDC化）

6. develop 向け CD（イメージ配布まで）
- push: develop をトリガー
- frontend/backend の Docker image を build
- ACR へ push（dev-<shortsha>, dev-latest, sha-<fullsha>）

7. Azure に AKS をデプロイ（dev→stg→prod の順）
- まず dev AKS を作成して疎通確認
- 次に stg/prod を同構成で展開

8. k8s/ 配下に Helm チャート作成
- Chart.yaml
- values.yaml, values-dev.yaml, values-stg.yaml, values-prod.yaml
- k8s/templates/*（frontend/backend/ingress 等）

9. develop CD にデプロイ工程を追加
- step 6 の後段に helm upgrade --install を追加
- values-dev.yaml で dev AKS へ自動デプロイ

10. release 起点 CD（stg/prod）
- release: published トリガー
- stg-v* は staging、v* は production
- build/push 後に values-stg.yaml / values-prod.yaml でデプロイ

11. 承認ゲートと運用ルール
- stg/prod Environment に手動承認を設定
- タグ規約とブランチ規約を README/運用ドキュメントへ明記

12. ドキュメント更新
- README.md, pre-check.md, AGENTS.md
- k8s/ 配置方針と CI/CD フローを反映

この順なら、CI品質担保 → イメージ供給 → AKS配備 を段階的に固められます。
