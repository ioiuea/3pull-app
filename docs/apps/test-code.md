# テストコードガイド（Frontend / Backend）

このドキュメントは、テストコードの「設置先」と「記載方法」を定義します。  
対象は `apps/frontend` と `apps/backend` です。

## 基本方針

- テストは仕様の固定が目的です。正常系だけでなく、失敗系・境界値も対象にします。
- テスト名は「何を保証するか」が読める文にします。
- 1テスト1責務を原則にし、失敗時に原因が追える粒度で分割します。
- 外部依存（ネットワーク、時刻、乱数、環境変数）はモックまたは固定化して、再現性を担保します。

## コメント方針（必須）

- テストコードには「何をしているか」を丁寧に説明するコメントを必ず書きます。
- 特に次を必須コメント対象にします。
  - なぜそのケースを検証するのか（背景・回帰リスク）
  - モックや固定値の意図（例: `Date.now` 固定理由）
  - 期待値の意味（なぜその値が正しいか）
- コメントは実装の言い換えではなく、仕様意図を説明します。

## フロントエンド（Vitest）

### 利用基盤

- テストランナー: `vitest`
- 環境: `jsdom`
- 設定ファイル: `apps/frontend/vitest.config.ts`
- セットアップ: `apps/frontend/test/vitest.setup.ts`

### 設置先

- 原則: `apps/frontend/test/`
- ファイル名: `*.test.ts` / `*.test.tsx`
- モック: `apps/frontend/test/mocks/`（共通化する場合）
- 配置は「対象モジュールが分かる名前」を付けます。
  - 例: `apps/frontend/test/auth.api-fetch.test.ts`
  - 例: `apps/frontend/test/i18n.test.ts`

### 書き方

- `describe` で機能単位、`it` で仕様単位に分けます。
- `beforeEach` / `afterEach` でモック状態を初期化し、テスト間の汚染を防ぎます。
- モジュールスコープ state を持つ実装は `vi.resetModules()` で毎テスト初期化します。
- API 通信は `fetch` をモックし、I/O を伴わないユニットテストにします。

```ts
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

// このテストは「未認証時に API 本体を呼ばない」仕様を固定する。
// 認証エンドポイントの失敗時に誤送信しないことがセキュリティ上重要。
describe("auth/api-fetch", () => {
  beforeEach(() => {
    // テスト間のモック汚染を防ぎ、毎回同条件で開始する。
    vi.restoreAllMocks();
  });

  afterEach(() => {
    // 後処理でも再初期化して、別ファイルへの影響を遮断する。
    vi.restoreAllMocks();
  });

  it("returns 401 and does not call protected API when token endpoint is unauthorized", async () => {
    // このモックは access-token が 401 を返す状況を再現する。
    const fetchMock = vi.fn().mockResolvedValueOnce(new Response(null, { status: 401 }));
    vi.stubGlobal("fetch", fetchMock);

    const { fetchWithApiAuth } = await import("@/lib/auth/api-fetch");
    const result = await fetchWithApiAuth("/api/protected");

    // 期待値は「not_authenticated を返す」こと。
    expect(result).toEqual({ ok: false, status: 401, error: "not_authenticated" });
    // API本体に進んでいないことを呼び出し回数で保証する。
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});
```

### 実行コマンド

- `pnpm --dir apps/frontend run test:run`
- `make frontend-test`

## バックエンド（pytest）

### 利用基盤

- テストランナー: `pytest`
- 設定: `apps/backend/pyproject.toml` の `[tool.pytest.ini_options]`
- `testpaths = ["test"]` のため、`apps/backend/test/` 配下が対象です。

### 設置先

- 原則: `apps/backend/test/`
- ファイル名: `test_*.py`
- 機能単位で分けて配置します。
  - 例: `apps/backend/test/test_health_service.py`
- 必要に応じてサブディレクトリ化します。
  - 例: `apps/backend/test/services/test_user_service.py`
  - 例: `apps/backend/test/api/test_auth_router.py`

### 書き方

- 1テストにつき1仕様を明示します。
- 関数名は `test_<condition>_<expected>` 形式で意図を残します。
- 単体テストでは DB/外部APIを直接呼ばず、境界をモックします。
- `pytest-asyncio`（`asyncio_mode = "auto"`）を前提に、非同期処理は `async def` テストで検証します。

```py
from app.services.health import _host_port_from_url


def test_host_port_from_url_uses_explicit_port() -> None:
    # 明示ポートがある URL は、その値を優先する仕様を検証する。
    # 接続先誤判定を防ぐため、最も重要な正常系ケース。
    assert _host_port_from_url("postgresql://localhost:6543/app", 5432) == (
        "localhost",
        6543,
    )


def test_host_port_from_url_returns_none_on_invalid_port() -> None:
    # ポート範囲外の URL は不正入力として None を返す。
    # 例外を投げずに「接続不可」と判定できることを保証する。
    assert _host_port_from_url("postgresql://localhost:99999/app", 5432) is None
```

### 実行コマンド

- `uv --directory apps/backend run pytest`
- `make backend-test`

## テスト追加時チェックリスト

- 設置先と命名がルールに合っているか。
- 各テストに仕様意図のコメントが付いているか。
- 正常系だけでなく、異常系・境界値を含んでいるか。
- モックや時刻固定などで再現性を確保しているか。
- ローカルで対象テストを実行し、失敗時メッセージが理解可能か。

## 関連ドキュメント

- `docs/apps/form-validation.md`
- `docs/apps/state.md`
- `docs/apps/api-protect.md`
