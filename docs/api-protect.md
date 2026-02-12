# API 保護ガイド

このドキュメントは、現在の実装における「フロントエンドからバックエンド API を保護付きで呼び出す仕組み」を説明します。  
対象は次の3領域です。

- `apps/frontend/lib/auth`
- `apps/frontend/app/api/auth`
- `apps/backend/app/core/security`

## 概要

- Web のログインセッション管理は Better Auth（Cookie）で行います。
- ただしバックエンド API 呼び出しは Cookie 直渡しではなく、短命 JWT（RS256）を `Authorization: Bearer` で送ります。
- JWT はフロントエンドの Route Handler（`/api/auth/access-token`）で、Better Auth セッションを確認した後に発行します。
- バックエンドは公開鍵で JWT を検証し、検証成功時のみ API を実行します。

## 主要ファイルと責務

- `apps/frontend/lib/auth/server.ts`
  - Better Auth のサーバー設定本体（プロバイダ、DB アダプタ、プラグイン）です。

- `apps/frontend/lib/auth/client.ts`
  - クライアント側から Better Auth を呼ぶための SDK です。

- `apps/frontend/app/api/auth/[...all]/route.ts`
  - Better Auth の標準 API エンドポイントを公開します。

- `apps/frontend/app/api/auth/access-token/route.ts`
  - Better Auth セッションを検証し、バックエンド API 用の短命 JWT を返します。

- `apps/frontend/server/sign-api-token.ts`
  - JWT 署名処理（RS256）を担当します。
  - `JWT_PRIVATE_KEY` で署名し、`iss`/`aud`/`exp` を付与します。

- `apps/frontend/lib/auth/api-fetch.ts`
  - API 呼び出しラッパーです。
  - 必要時に `/api/auth/access-token` からトークンを取得し、`Authorization: Bearer` を付与します。
  - トークンはブラウザメモリに短期キャッシュします。

- `apps/backend/app/core/security/auth.py`
  - `Authorization: Bearer` を抽出し、RS256 署名を検証します。
  - 検証済み情報を `ApiTokenPrincipal` として API 層へ渡します。

- `apps/backend/app/core/security/__init__.py`
  - `get_current_principal` と `ApiTokenPrincipal` の再エクスポートです。

## リクエストフロー（高レベル）

1. ユーザーが Web にログインし、Better Auth のセッション Cookie を持つ。
2. フロントの API ラッパー（`api-fetch.ts`）がトークンを必要としたとき、`/api/auth/access-token` を呼ぶ。
3. `access-token` Route Handler が `auth.api.getSession()` でセッションを検証する。
4. 認証済みなら `sign-api-token.ts` で短命 JWT（RS256）を発行して返す。
5. フロントはバックエンド API 呼び出し時に `Authorization: Bearer <JWT>` を付ける。
6. バックエンド `get_current_principal` が JWT を検証し、OK の場合のみエンドポイント処理を継続する。

## バックエンド検証仕様

- 実装: `apps/backend/app/core/security/auth.py`
- 署名アルゴリズム: `RS256`（固定）
- 入力: `Authorization: Bearer <token>`
- 検証項目:
  - 署名（`JWT_PUBLIC_KEY`）
  - `iss`（`JWT_ISSUER` が設定されている場合）
  - `aud`（`JWT_AUDIENCE` が設定されている場合）
  - `exp`
  - `sub`（必須）
- 失敗時:
  - `401 Unauthorized`
  - `WWW-Authenticate: Bearer`

## 保護対象 API

- 原則: `apps/backend/app/api/{バージョン}/routers` 配下の API は保護対象です。
- 実装時は各ルーターで `Depends(get_current_principal)` を適用し、JWT 検証を必須にします。
- 未認証または不正トークンの場合は `401 Unauthorized` を返します。

## JWT クレーム（現実装）

`apps/frontend/server/sign-api-token.ts` で、主に次のクレームを付与します。

- 標準クレーム:
  - `sub`（ユーザーID）
  - `iss`（既定: `3pull-web`）
  - `aud`（既定: `3pull-api`）
  - `iat`
  - `exp`（既定: 5分）
- アプリ用クレーム:
  - `email`
  - `name`
  - `email_verified`
  - `active_organization_id`
  - `organization_role`（必要時）

## 環境変数

### フロントエンド（署名側）

- 参照: `apps/frontend/.env.example`
- 必須:
  - `JWT_PRIVATE_KEY`
- 推奨:
  - `JWT_ISSUER`
  - `JWT_AUDIENCE`

### バックエンド（検証側）

- 参照: `apps/backend/.env.example`
- 必須:
  - `JWT_PUBLIC_KEY`
- 推奨:
  - `JWT_ISSUER`
  - `JWT_AUDIENCE`

## 運用上の注意

- `JWT_PRIVATE_KEY` と `JWT_PUBLIC_KEY` は必ず対になる鍵を使ってください。
- `.env` で PEM を 1 行で持つ場合は `\n` エスケープが必要です（実装側で復元しています）。
- フロントのトークンキャッシュはメモリのみです。ページリロードで消える前提です。
- API 保護の責務はバックエンドにあります。フロント側の判定だけに依存しないでください。

## docs/auth.md との差分（実装準拠）

`docs/auth.md` では旧ファイル名の記載が一部残っていますが、実装上の正は次です。

- `apps/frontend/lib/auth.ts` → `apps/frontend/lib/auth/server.ts`
- `apps/frontend/lib/auth-client.ts` → `apps/frontend/lib/auth/client.ts`

本ガイドは、上記の現行実装に合わせて記載しています。
