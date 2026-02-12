# フロントエンド 状態管理ガイド

このドキュメントは、`apps/frontend` における状態管理の方針をまとめたものです。  
ローカル状態、グローバル状態（Zustand）、サーバサイド状態の使い分けを明確化し、実装判断を揃えることを目的とします。

## 概要

- 状態は「スコープが小さいものから順に」選択する。
- ページやコンポーネント内で完結するならローカル state を優先する。
- 複数コンポーネントで共有するクライアント状態のみ Zustand を利用する。
- フォーム状態は `react-hook-form`、サーバデータ取得は `SWR` など専用手段を優先する。
- サーバ由来データの真実は DB/API 側に置き、クライアント状態管理に混在させない。

## 使い分け早見表

| 対象                                 | 推奨手段                      | 例                                     |
| ------------------------------------ | ----------------------------- | -------------------------------------- |
| 単一コンポーネント内の一時状態       | `useState`                    | モーダル開閉、入力中テキスト、タブ選択 |
| 複雑な局所状態遷移                   | `useReducer`                  | 複数イベントで状態遷移するウィザード   |
| フォーム入力/エラー                  | `react-hook-form` + `zod`     | ログイン、サインアップ、設定フォーム   |
| 複数コンポーネントで共有する UI 状態 | `zustand`                     | 検索条件、選択中ID、表示モード         |
| API 由来のサーバ状態                 | `SWR`（または fetch + cache） | 一覧データ、詳細データ、再取得管理     |
| サーバ実行時のみ必要な状態           | Server Component / Action     | セッション、ヘッダー、Cookie、DB結果   |

## 判断フロー

1. その状態は 1 コンポーネントだけで使うか。
2. Yes なら `useState` / `useReducer` を使う。
3. No なら、サーバ由来データか UI 共有状態かを判定する。
4. サーバ由来なら `SWR`、UI 共有状態なら `zustand` を使う。

## ローカル状態管理

- `useState` を第一選択にする。
- 親子で 2-3 階層までなら props 受け渡しを優先する。
- 画面離脱で破棄されてよい値はグローバル化しない。

```tsx
const ExampleClient = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [keyword, setKeyword] = useState("");

  return (
    <>
      <Button onClick={() => setIsOpen((prev) => !prev)}>Toggle</Button>
      <Input value={keyword} onChange={(e) => setKeyword(e.target.value)} />
    </>
  );
};
```

## グローバル状態管理（Zustand）

### 方針

- グローバル状態は `apps/frontend/store/` に集約する。
- ストアは `state` と `action` を同一型に定義する。
- 命名は `useXxxStore` に統一する。
- 副作用（API 呼び出し、Router 遷移、toast）はコンポーネント側に置き、ストアは状態更新責務に寄せる。

### 実装例

`apps/frontend/store/sampleStore.ts` と同様のパターンで定義する。

```ts
import { create } from "zustand";

type SampleState = {
  count: number;
  label: string;
  setLabel: (label: string) => void;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
};

export const useSampleStore = create<SampleState>((set) => ({
  count: 0,
  label: "Clicks",
  setLabel: (label) => set({ label }),
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}));
```

### 利用例

```tsx
"use client";

import { useSampleStore } from "@/store/sampleStore";

export const CounterClient = () => {
  const count = useSampleStore((state) => state.count);
  const increment = useSampleStore((state) => state.increment);
  const reset = useSampleStore((state) => state.reset);

  return (
    <div>
      <p>{count}</p>
      <Button onClick={increment}>+1</Button>
      <Button onClick={reset}>Reset</Button>
    </div>
  );
};
```

## パフォーマンスと設計ルール

- `useStore()` で全 state をまとめて読むより、selector で必要な値だけ購読する。
- ストアを肥大化させず、関心ごとごとに分割する。
- 永続化が必要な場合のみ `persist` を検討し、保存対象は最小限にする。
- サーバデータのキャッシュ用途で Zustand を使いすぎない。

## サーバサイド状態管理（Next.js / Backend）

### 基本方針

- サーバサイドは「リクエスト単位の一時状態」を扱う。
- 永続状態の正は DB（`auth` / `core`）および外部ストレージに置く。
- プロセスメモリを正データとして扱わない（再起動・スケールで失われるため）。

### フロントエンド（Next.js App Router）

- `app/[lang]/**/page.tsx` の Server Component で `params`, `cookies`, `headers` を解決する。
- 認証情報や辞書など、初期描画に必要な情報はサーバで取得してクライアントへ props で渡す。
- 更新系は Server Actions（`apps/frontend/server/*`）や Route Handler（`apps/frontend/app/api/**`）に集約する。
- 認証トークンのような機密データは `Cache-Control: no-store` を徹底する。

### バックエンド（FastAPI）

- API は基本的に stateless に保ち、状態は DB/Redis 等へ保存する。
- 認可情報は `Authorization` ヘッダー由来の JWT から毎リクエスト検証する。
- サービス層は request ごとの入力から結果を導出する構造を優先する。

### サーバサイド状態のアンチパターン

- グローバル変数にユーザー別状態を保持する。
- クライアント表示用データを Server Action 内のメモリキャッシュだけで保持する。
- サーバ状態の更新後にクライアント再取得をせず、古い表示を許容してしまう。

## アンチパターン

- フォーム入力値を丸ごと Zustand に置く。
- 一時的なモーダル開閉や hover 状態をグローバルにする。
- API フェッチと UI 状態を同一ストアに混在させる。
- 画面固有の値を「将来使うかも」で先にグローバル化する。
- サーバ由来データを Zustand のみで正管理しようとする。

## 主要ファイルと責務

- `apps/frontend/store/sampleStore.ts`
  - Zustand ストア定義のサンプル。
- `apps/frontend/features/sample/zustand/index.tsx`
  - ストア利用と action 呼び出しのサンプル。
- `apps/frontend/features/*`
  - 画面専用ローカル状態（`useState`/`useReducer`）の実装場所。
- `apps/frontend/server/*`
  - Server Actions。認証や DB 操作などサーバ責務の状態更新を担当。
- `apps/frontend/app/api/**/route.ts`
  - Route Handler。サーバサイド処理とレスポンス制御（例: no-store）を担当。

## 関連ドキュメント

- `docs/form-validation.md`
- `docs/fetch-strategy.md`
- `docs/ui-design.md`
- `docs/i18n.md`
