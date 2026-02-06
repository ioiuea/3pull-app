# Authentication guide

This document explains how authentication is wired in the web app, which files are involved, and how the pieces relate.
このドキュメントは、Web アプリにおける認証の構成、関係ファイル、責務のつながりを説明します。

## Overview

- Auth is implemented with Better Auth, exposed via a Next.js route handler and consumed by server actions and client hooks.
- 認証は Better Auth で実装され、Next.js の Route Handler で公開され、サーバアクションとクライアントフックから利用されます。

- Auth data lives in the `auth` schema, managed by Drizzle migrations and schema definitions.
- 認証データは `auth` スキーマに格納され、Drizzle の schema と migration で管理されます。

- Edge middleware in `apps/web/proxy.ts` handles auth gating for protected routes.
- `apps/web/proxy.ts` の Edge middleware が保護ルートの認証判定を行います。

## Key files and responsibilities

- `apps/web/lib/auth.ts`
  - Configures Better Auth (email/password, social provider, email sending, org plugin).
  - Better Auth の本体設定（メール/パスワード、ソーシャル、メール送信、組織プラグイン）を定義します。

- `apps/web/app/api/auth/[...all]/route.ts`
  - Exposes Better Auth as a Next.js Route Handler (`GET`/`POST`).
  - Better Auth を Next.js の Route Handler として公開します。

- `apps/web/lib/auth-client.ts`
  - Client-side Better Auth SDK instance used by UI components.
  - UI から利用するクライアント SDK を定義します。

- `apps/web/server/*`
  - Server actions that call `auth.api.*` (sign-in, sign-up, permissions, organization actions).
  - `auth.api.*` を呼ぶサーバアクション群（サインイン/サインアップ/権限/組織関連）。

- `apps/web/proxy.ts`
  - Edge middleware; performs auth checks for non-public routes via session cookies.
  - Edge middleware として公開パス以外の認証判定を行います（session cookie 参照）。

- `apps/web/drizzle/schema.ts`
  - Defines the `auth` schema tables (user, session, account, member, organization, etc.).
  - `auth` スキーマのテーブル定義を持ちます（user/session/account/member/organization など）。

- `apps/web/drizzle/migrations/*`
  - SQL migrations that create the `auth` schema and tables.
  - `auth` スキーマ/テーブル作成のマイグレーション SQL を保持します。

- `apps/web/drizzle.config.ts`
  - Drizzle Kit config; filters schema to `auth` and uses `DATABASE_URL`.
  - Drizzle Kit の設定。`auth` スキーマに限定し `DATABASE_URL` を使用します。

- `apps/web/.env.example`
  - Lists required auth-related env vars (Better Auth, DB, Resend, Microsoft).
  - 認証に必要な環境変数を列挙しています（Better Auth, DB, Resend, Microsoft）。

## Request flow (high level)

1) Browser requests a protected page.
   ブラウザが保護ページへアクセス。

2) `apps/web/proxy.ts` checks if the path is public; if not, it checks session cookie and redirects to `/login` when missing.
   `apps/web/proxy.ts` が公開パスか判定し、非公開なら session cookie を確認。なければ `/login` にリダイレクト。

3) On the login UI, client code uses `authClient` or server actions to sign in.
   ログイン UI では `authClient` またはサーバアクションでサインイン。

4) Better Auth endpoints are served from `apps/web/app/api/auth/[...all]/route.ts`.
   Better Auth の API は `apps/web/app/api/auth/[...all]/route.ts` で提供。

5) After login, server actions and page layouts can call `auth.api.getSession()` to access session data.
   ログイン後、サーバアクションやレイアウトが `auth.api.getSession()` でセッションを取得。

## Auth configuration details

### Better Auth core (`apps/web/lib/auth.ts`)

- Email/password auth is enabled, with email verification required.
- メール/パスワード認証が有効で、メール確認が必須です。

- Microsoft Entra ID is configured as a social provider using env vars.
- Microsoft Entra ID は環境変数で設定されるソーシャルプロバイダです。

- Resend is used to send verification and password reset emails.
- Resend を利用して検証メール/パスワード再発行メールを送信します。

- Organization plugin and access control are configured via `lib/auth/permissions.ts`.
- 組織プラグインとアクセス制御は `lib/auth/permissions.ts` で定義します。

### Server actions (`apps/web/server/*`)

- `users.ts` wraps `auth.api.signInEmail`, `signUpEmail`, `getSession` and handles DB lookups.
- `users.ts` は `auth.api.signInEmail`/`signUpEmail`/`getSession` をラップし、DB 参照も行います。

- `members.ts` uses `auth.api.addMember` and direct DB operations.
- `members.ts` は `auth.api.addMember` と DB 操作を組み合わせます。

- `permissions.ts` checks permissions using `auth.api.hasPermission`.
- `permissions.ts` は `auth.api.hasPermission` で権限を確認します。

## Database layer (Drizzle)

- `apps/web/drizzle/schema.ts` defines tables in the `auth` schema used by Better Auth.
- `apps/web/drizzle/schema.ts` が Better Auth 用の `auth` スキーマテーブルを定義します。

- `apps/web/drizzle.config.ts` sets `schemaFilter: ["auth"]`, so only `auth` schema is managed by this app.
- `apps/web/drizzle.config.ts` の `schemaFilter: ["auth"]` により、`auth` スキーマのみを管理対象にします。

## Environment variables

Auth-related env vars live in `apps/web/.env.example`:
認証関連の環境変数は `apps/web/.env.example` にあります。

- `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL`
- `DATABASE_URL` (includes `?schema=auth`)
- `MICROSOFT_CLIENT_ID`, `MICROSOFT_CLIENT_SECRET`, `MICROSOFT_TENANT_ID`
- `RESEND_API_KEY`, `EMAIL_SENDER_NAME`, `EMAIL_SENDER_ADDRESS`

## Notes and dependencies to be careful about

- `apps/web/proxy.ts` is the gatekeeper for protected routes; ensure public paths are correct to avoid blocking login.
- `apps/web/proxy.ts` は保護ルートの入口です。公開パス設定ミスはログイン不能につながります。

- The `auth` schema is owned by `apps/web/drizzle`; do not modify `apps/api` migrations for auth tables.
- `auth` スキーマは `apps/web/drizzle` の責務です。`apps/api` 側で変更しないでください。

- `apps/web/lib/auth.ts` relies on env vars; missing keys will break login or email flows.
- `apps/web/lib/auth.ts` は環境変数に依存します。不足するとログインやメール送信が失敗します。
