# AGENT 指針（リポジトリ全体 / for OpenAI Code Assistant）

このリポジトリは **モノレポ構成** です。  
各ディレクトリと責務を正しく理解した上で、責務外のコードや設定を混在させないようにしてください。

---

## 1. リポジトリ全体構成と責務分離

### 1-1. ルート直下

- `.gitignore` / `.dockerignore`  

### 1-2. ディレクトリ責務

- `apps/`
  - `apps/web` : フロントエンド（Next.js / Auth.js / Drizzle）
  - `apps/api` : バックエンド（FastAPI / SQLAlchemy + Alembic）
- `db/`
  - Postgres 初期化スクリプト群。DB/スキーマ/ロールの作成・初期設定。
- `infra/`
  - Helm / Dockerfile などの **インフラ周り一式**。
- `docs/`
  - 仕様・設計・運用（ランブック）などのドキュメント群。
- `ops/`
  - 運用系ツール・スクリプトを置くことを想定（運用責務でありアプリロジックは置かない）。

> 原則として、**プロダクトコードは `apps/`、インフラは `infra/`、DB 初期化は `db/`、運用は `ops/`、ドキュメントは `docs/`** という責務分離を崩さないでください。

---


---

## 4. インフラ構成（infra/）

### 4-1. Dockerfile

- `infra/docker/api.Dockerfile` : FastAPI 用
- `infra/docker/web.Dockerfile` : Next.js 用  
→ 役割ごとに分離し、ビルドコンテキストや依存を混ぜないようにしてください。


---

## 5. データベースとスキーマ責務

### 5-1. 利用ミドルウェア

- コア DB : Azure Database for PostgreSQL
- Chat Message : Azure CosmosDB
- Cache / Queue : Azure for Redis

### 5-2. Postgres 初期化（db/）

- `db/postgres/init/*.sh`  
  - DB 作成・スキーマ作成・ロール・権限・search_path 設定などを行うシェルスクリプト群。
  - 変更時は **マイグレーション方針と矛盾しないか** を確認してください（Alembic / Drizzle の責務を壊さない）。

### 5-3. スキーマ分離と管理責務

- `auth` スキーマ（認証系）
  - 管理者: `apps/web/drizzle`
  - マイグレーション: `apps/web/drizzle/migrations/`
  - ORM: Drizzle
- `core` スキーマ（業務系）
  - 管理者: `apps/api/alembic`
  - マイグレーション: `apps/api/alembic/versions/`
  - ORM: SQLAlchemy（models は `apps/api/app/models/`）

> **重要ポリシー**  
> - `auth` は Web / Auth 領域のためのスキーマ、`core` は業務ドメインのためのスキーマです。  
> - 片方のスキーマ変更で済むものを、もう一方にまたがって実装しないでください。  
> - どうしても両方に影響する変更を行う場合は、  
>   - どのディレクトリ・ツールに影響があるか  
>   - どのマイグレーションをどの順で適用すべきか  
>   をコメント・ドキュメント（`docs/` など）に明示してください。

---

## 6. フロントエンド（apps/web）

### 6-1. 技術スタックと構成

- Next.js（App Router）
- pnpm による依存管理
- i18n : 現状は未導入（`app/[lang]/...` や `dictionaries/` は未配置）
- UI : `shadcn/ui` を `components/ui/` 配下に集約
- 状態管理 : `store/` で Zustand を使用
- 認証 : Auth.js + Drizzle (`auth` スキーマ)
- Drizzle : `apps/web/drizzle/`（`schema.ts`）+ `apps/web/drizzle.config.ts` + `apps/web/drizzle/migrations/`

### 6-2. ディレクトリの主な役割

- `app/` : ページルート（SSR）／言語別ルーティング／Auth route
- `features/` : CSR ベースの機能モジュール
- `components/` : 再利用コンポーネント
- `lib/` : アプリ固有ライブラリ（例: DB クライアントラッパ）
- `utils/` : 汎用ユーティリティ
- `store/` : Zustand ストア
- `drizzle/` : Drizzle スキーマ（`schema.ts`）
- 認証プロバイダ（Credentials / Microsoft Entra ID / GitHub）の有効化設定とクライアント情報は `apps/web/features/settings/auth` から管理され、DB の `auth_provider_configs` に保存されます。`.env` 内の `AUTH_*` 変数は初期値としてのみ利用してください（UI から更新した設定が優先されます）。

> **AGENT へ**:  
> - ページ起点の UI は `app/`、機能単位の再利用可能 UI ロジックは `features/` に置く方針です。  
> - DB スキーマの変更が必要な場合は、`apps/web/drizzle/schema.ts` と Drizzle migration をセットで扱ってください。

### 6-7. app ルータとクライアントコンポーネント配置ルール

- `app/` 配下の `page.tsx` はサーバコンポーネントとして配置します。
- `app/` と同階層の `features/` に、ページと同名のフォルダを作成しクライアントコンポーネントを配置します。
- クライアントコンポーネントの親は `features/<page>/index.tsx` とします。
- サーバサイドの関数コンポーネント名は `FeatureNamePage`、クライアント側は `FeatureNameClient` の命名に統一します（例: feature が `sample` の場合は `SamplePage` / `SampleClient`）。
- React コンポーネントは `export default function` を使わず、アロー関数コンポーネント（`const X = () => {}`）で統一します。

### 6-3. Zustand 利用ルール

- グローバル状態は `apps/web/store/` に集約し、ページ内で閉じる状態はローカル state を優先します。
- ストアは `useXxxStore` の命名に揃え、更新関数は action としてまとめます。

### 6-4. Zod 利用ルール

- 入力検証や API 受信データの整合性確認に利用します。
- スキーマは利用箇所の近く（ページ/feature）に置き、再利用が必要なら `utils/` に切り出します。

### 6-5. shadcn/ui 利用ルール

- UI は `components/ui/` のコンポーネントを基本として組み立てます。
- 直接クラスで装飾する場合でも、shadcn の構造/トークンに合わせて一貫性を保ちます。

### 6-6. motion 利用ルール

- ページの主要セクションに限定して控えめに使用し、過度なアニメーションは避けます。
- アニメーションは `motion` のコンポーネントに集約し、CSS と混在させて挙動を分散させないようにします。

---

## 7. バックエンド（apps/api）

### 7-1. 技術スタック

- FastAPI
- SQLAlchemy + Alembic
- uv（Python 依存管理）
- Pydantic Settings による設定・環境変数管理
- structlog による構造化ログ
- pytest / ruff / pyright


## 11. AGENTS.md の運用ルール（必ず読んでください）

- この `AGENTS.md` は、**OpenAI のコードアシスタント（Codex 等）がリポジトリ全体方針を理解するためのガイド**です。
- そのため、以下を必ず守ってください：

1. **作業（タスク）完了時の査読**
   - AGENT がリポジトリに対して非自明な変更（構成・責務・起動フロー・DB やインフラの設計変更など）を行った場合、  
     **作業の最後に必ず `AGENTS.md` を開き、内容が現状の構成と一致しているか査読**してください。
2. **齟齬があれば、その場で更新**
   - 実際のフォルダ構成・Make タスク・スキーマ責務・環境変数設計などと食い違いがあれば、  
     **同じ変更セット（同じ PR / 同じコミットレンジ）内で `AGENTS.md` を更新**するよう努めてください。
3. **曖昧な場合の扱い**
   - 方針が変わったかどうか判断に迷う場合は、
     - 実際のコード・設定ファイルを確認し、
     - 必要なら `docs/` の関連ドキュメントも参照し、
     - それでも不明な場合は、`AGENTS.md` 上に「現時点の前提」や「要確認事項」として注記を残してください。

> **まとめ**:  
> - **「実際の環境・コードが真実」** です。  
> - `AGENTS.md` はそれを反映する **解説レイヤー** であり、  
>   作業後に必ず見直して、**リポジトリの現実とずれないように保守すること** を AGENT の重要な責務とします。
