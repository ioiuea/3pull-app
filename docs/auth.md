# 認証ガイド

このドキュメントは、Web アプリにおける認証の構成、関係ファイル、責務のつながりを説明します。

## 概要

- 認証は Better Auth で実装され、Next.js の Route Handler で公開され、サーバアクションとクライアントフックから利用されます。
- 認証データは `auth` スキーマに格納され、Drizzle の schema と migration で管理されます。
- `apps/web/proxy.ts` の Edge middleware が保護ルートの認証判定を行います。

## 主要ファイルと責務

- `apps/web/lib/auth.ts`
  - Better Auth の本体設定（メール/パスワード、ソーシャル、メール送信、組織プラグイン）を定義します。

- `apps/web/app/api/auth/[...all]/route.ts`
  - Better Auth を Next.js の Route Handler として公開します。

- `apps/web/lib/auth-client.ts`
  - UI から利用するクライアント SDK を定義します。

- `apps/web/server/*`
  - `auth.api.*` を呼ぶサーバアクション群（サインイン/サインアップ/権限/組織関連）。

- `apps/web/proxy.ts`
  - Edge middleware として公開パス以外の認証判定を行います（session cookie 参照）。

- `apps/web/drizzle/schema.ts`
  - `auth` スキーマのテーブル定義を持ちます（user/session/account/member/organization など）。

- `apps/web/drizzle/migrations/*`
  - `auth` スキーマ/テーブル作成のマイグレーション SQL を保持します。

- `apps/web/drizzle.config.ts`
  - Drizzle Kit の設定。`auth` スキーマに限定し `DATABASE_URL` を使用します。

- `apps/web/.env.example`
  - 認証に必要な環境変数を列挙しています（Better Auth, DB, Resend, Microsoft）。

## リクエストフロー（高レベル）

1) ブラウザが保護ページへアクセス。

2) `apps/web/proxy.ts` が公開パスか判定し、非公開なら session cookie を確認。なければ `/login` にリダイレクト。

3) ログイン UI では `authClient` またはサーバアクションでサインイン。

4) Better Auth の API は `apps/web/app/api/auth/[...all]/route.ts` で提供。

5) ログイン後、サーバアクションやレイアウトが `auth.api.getSession()` でセッションを取得。

## 認証設定の詳細

### Better Auth コア（`apps/web/lib/auth.ts`）

- メール/パスワード認証が有効で、メール確認が必須です。
- Microsoft Entra ID は環境変数で設定されるソーシャルプロバイダです。
- Resend を利用して検証メール/パスワード再発行メールを送信します。
- 組織プラグインとアクセス制御は `lib/auth/permissions.ts` で定義します。

### サーバアクション（`apps/web/server/*`）

- `users.ts` は `auth.api.signInEmail`/`signUpEmail`/`getSession` をラップし、DB 参照も行います。
- `members.ts` は `auth.api.addMember` と DB 操作を組み合わせます。
- `permissions.ts` は `auth.api.hasPermission` で権限を確認します。

## DB レイヤ（Drizzle）

- `apps/web/drizzle/schema.ts` が Better Auth 用の `auth` スキーマテーブルを定義します。
- `apps/web/drizzle.config.ts` の `schemaFilter: ["auth"]` により、`auth` スキーマのみを管理対象にします。

## 環境変数

認証関連の環境変数は `apps/web/.env.example` にあります。

- `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`
- `DATABASE_URL`（`?schema=auth` を含む）
- `MICROSOFT_CLIENT_ID`, `MICROSOFT_CLIENT_SECRET`, `MICROSOFT_TENANT_ID`
- `RESEND_API_KEY`, `EMAIL_SENDER_NAME`, `EMAIL_SENDER_ADDRESS`

## 注意点

- `apps/web/proxy.ts` は保護ルートの入口です。公開パス設定ミスはログイン不能につながります。
- `auth` スキーマは `apps/web/drizzle` の責務です。`apps/api` 側で変更しないでください。
- `apps/web/lib/auth.ts` は環境変数に依存します。不足するとログインやメール送信が失敗します。
