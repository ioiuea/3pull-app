# フロントエンド データフェッチ戦略（SWR）

このドキュメントは、`apps/frontend` におけるデータ取得戦略を定義します。  
特に `SWR` を使ったクライアント側のサーバ状態管理を対象にします。

## 目的

- データ取得の実装を統一し、画面ごとの挙動差を減らす。
- ローディング/エラー/空状態を一貫して扱う。
- 認証付き API 呼び出しとキャッシュ更新の責務を明確化する。

## 基本方針

- サーバ状態の取得は `SWR` を標準とする。
- 認証付き fetch は `apps/frontend/lib/auth/api-fetch.ts` を利用する。
- 取得データは Zod で検証し、不正レスポンスを早期に検知する。
- UI の一時状態（入力中キーワード等）とサーバ状態を分離する。

## 層ごとの責務

1. Server Component（`app/[lang]/**/page.tsx`）
- `lang` や辞書など初期描画に必要な情報を解決してクライアントへ渡す。

2. Client Component（`features/**`）
- `useSWR` で API データを取得し、表示状態を管理する。

3. Fetch utility（`lib/auth/api-fetch.ts`）
- トークン付与、レスポンス整形、未認証時の扱いを共通化する。

## 標準パターン

### 1. SWR キー設計

- キーは「API パス + クエリ」で一意にする。
- クエリは `encodeURIComponent` で正規化する。
- バージョン付き API は `API_VERSION` を含める。

```ts
const key = `/backend/${API_VERSION}/sample?q=${encodeURIComponent(query)}`;
```

### 2. fetcher 実装

- `fetchWithApiAuthRaw` を使って認証ヘッダーを付与する。
- `response.ok` 判定を必ず行う。
- `response.json()` の結果を Zod で `parse` する。

```ts
const fetcher = async (url: string) => {
  const response = await fetchWithApiAuthRaw(url, { cache: "no-store" });
  if (!response || !response.ok) {
    throw new Error("fetch failed");
  }
  const data = await response.json();
  return ResponseSchema.parse(data);
};
```

### 3. 画面状態の描画

- `isLoading`: Skeleton
- `error`: Alert（再試行導線を必要に応じて追加）
- `data`: 正常表示
- `data.items.length === 0`: Empty state

このパターンは `apps/frontend/features/sample/swr/index.tsx` と同じ構成です。

## 更新系（Mutation）戦略

- POST/PUT/DELETE 成功後は `mutate(key)` または `mutate(matchFn)` で再取得する。
- 楽観更新が必要な場合だけ `mutate(key, updater, { revalidate: false })` を使う。
- 失敗時のロールバック手順を決めずに楽観更新を導入しない。

```ts
import { mutate } from "swr";

await updateItem(input);
await mutate(`/backend/${API_VERSION}/items`);
```

## 再検証（Revalidation）方針

- デフォルトの再検証挙動を基本とする。
- 高頻度 API や重い API は画面要件に応じて次を明示設定する。
  - `revalidateOnFocus: false`
  - `refreshInterval`
  - `dedupingInterval`
- 要件なくグローバル設定を変更しない。

## サーバサイド状態との接続

- 初期表示に必要な静的に近い情報（辞書・言語）は Server Component で解決する。
- ユーザー操作で変化するサーバ状態は Client 側で SWR 管理する。
- 認証情報や署名トークンは Route Handler / Server Action 側で生成し、クライアントへ最小限のみ渡す。

## 避けるべき実装

- API レスポンスを Zustand に正データとして保存する。
- フェッチごとに ad-hoc な `fetch` 実装を増やす（認証/エラー処理が分散する）。
- Zod 検証なしで受信 JSON をそのまま UI へ渡す。
- ローディングやエラー状態を持たないまま描画する。

## 実装チェックリスト

- SWR キーが安定しているか（クエリの正規化含む）。
- fetcher で `!response.ok` を確実に失敗扱いしているか。
- レスポンススキーマを Zod で検証しているか。
- `isLoading` / `error` / `empty` / `success` を描き分けているか。
- 更新系のあとに `mutate` で再検証しているか。

## 主要ファイル

- `apps/frontend/features/sample/swr/index.tsx`
- `apps/frontend/lib/auth/api-fetch.ts`
- `apps/frontend/app/[lang]/sample/swr/page.tsx`

## 関連ドキュメント

- `docs/apps/state.md`
- `docs/apps/api-protect.md`
- `docs/apps/form-validation.md`
