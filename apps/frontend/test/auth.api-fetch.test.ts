import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

// JWT 文字列が必要なケース向けの最小ヘルパーです。
// 署名検証はこのモジュールの責務外なので、payload を読める形式だけ作っています。
const createJwt = (payload: Record<string, unknown>) => {
  const header = { alg: "none", typ: "JWT" }
  const toBase64Url = (value: unknown) =>
    btoa(JSON.stringify(value))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/g, "")

  return `${toBase64Url(header)}.${toBase64Url(payload)}.signature`
}

// このファイルは `lib/auth/api-fetch.ts` の振る舞いテストです。
// 外部 API との通信を実際には行わず、`fetch` をモックして
// 「認証トークン取得」「ヘッダ付与」「レスポンス整形」のルールを固定します。
describe("auth/api-fetch", () => {
  beforeEach(() => {
    // 各テストの開始時にモック状態を初期化し、テスト間の影響を遮断します。
    vi.restoreAllMocks()
  })

  afterEach(() => {
    // 終了時にも再度初期化して、次ファイルのテストへ汚染を持ち越さないようにします。
    vi.restoreAllMocks()
  })

  it("returns 401 result when access token endpoint is unauthorized", async () => {
    // 先に /api/auth/access-token で認証状態を確認する実装なので、
    // 未認証時は API 本体を叩かず 401 を返すことを確認します。
    vi.resetModules()
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(new Response(null, { status: 401 }))
    vi.stubGlobal("fetch", fetchMock)

    const { fetchWithApiAuth } = await import("@/lib/auth/api-fetch")
    const result = await fetchWithApiAuth("/api/protected")

    expect(result).toEqual({ ok: false, status: 401, error: "not_authenticated" })
    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(fetchMock).toHaveBeenCalledWith(
      "/api/auth/access-token",
      expect.objectContaining({ method: "GET" }),
    )
  })

  it("adds bearer token and parses successful json response", async () => {
    // 成功系: トークン取得後に Authorization ヘッダ付きで API を呼び、
    // JSON を data として返せるかを確認します。
    // tokenCache はモジュールスコープのため、毎テストで読み直して状態をリセットします。
    vi.resetModules()

    // `expiresAt > now + 5` 判定が安定するように現在時刻を固定します。
    vi.spyOn(Date, "now").mockReturnValue(1_700_000_000_000)

    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            accessToken: "token-1",
            expiresAt: 1_700_000_100,
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ id: "u1" }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      )
    vi.stubGlobal("fetch", fetchMock)

    const { fetchWithApiAuth } = await import("@/lib/auth/api-fetch")
    const result = await fetchWithApiAuth<{ id: string }>("/api/users/me", {
      method: "GET",
    })

    // 1回目: トークン取得, 2回目: 実 API 呼び出し、の2段階で成功することを確認します。
    expect(result).toEqual({ ok: true, status: 200, data: { id: "u1" } })
    expect(fetchMock).toHaveBeenCalledTimes(2)

    // 2回目の呼び出しに認証ヘッダが正しく付与されていることを検証します。
    const secondCallOptions = fetchMock.mock.calls[1][1] as RequestInit
    const headers = secondCallOptions.headers as Headers
    expect(headers.get("Authorization")).toBe("Bearer token-1")
    expect(headers.get("Content-Type")).toBe("application/json")
  })

  it("returns null data for 204 no content response", async () => {
    // 204 はレスポンス本文がないため、data は null を返す仕様です。
    // 204 を通常エラー扱いにしないことが、削除系 API の扱いやすさに直結します。
    vi.resetModules()
    vi.spyOn(Date, "now").mockReturnValue(1_700_000_000_000)

    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            accessToken: "token-2",
            expiresAt: 1_700_000_100,
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      )
      .mockResolvedValueOnce(new Response(null, { status: 204 }))
    vi.stubGlobal("fetch", fetchMock)

    const { fetchWithApiAuth } = await import("@/lib/auth/api-fetch")
    const result = await fetchWithApiAuth("/api/resource", { method: "DELETE" })

    expect(result).toEqual({ ok: true, status: 204, data: null })
  })

  it("supports plain text error responses", async () => {
    // API が JSON ではなく text を返すケースでも、
    // 失敗理由を error に格納できることを確認します。
    // バックエンドが一時的に text エラーを返しても UI 側で内容を表示できます。
    vi.resetModules()
    vi.spyOn(Date, "now").mockReturnValue(1_700_000_000_000)

    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            accessToken: "token-3",
            expiresAt: 1_700_000_100,
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      )
      .mockResolvedValueOnce(new Response("forbidden", { status: 403 }))
    vi.stubGlobal("fetch", fetchMock)

    const { fetchWithApiAuth } = await import("@/lib/auth/api-fetch")
    const result = await fetchWithApiAuth("/api/protected")

    expect(result).toEqual({ ok: false, status: 403, error: "forbidden" })
  })

  it("reuses cached access token while it is not expired", async () => {
    // キャッシュ有効期限内はトークン取得 API を毎回呼ばないことを確認します。
    // この挙動で不要な通信を抑えています。
    vi.resetModules()
    vi.spyOn(Date, "now").mockReturnValue(1_700_000_000_000)

    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            accessToken: "token-cache",
            expiresAt: 1_700_000_100,
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ ok: true }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ ok: true }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      )
    vi.stubGlobal("fetch", fetchMock)

    const { fetchWithApiAuth } = await import("@/lib/auth/api-fetch")
    await fetchWithApiAuth("/api/one")
    await fetchWithApiAuth("/api/two")

    // 呼び出し順がこの形なら、2回目は token endpoint を再取得していないと分かります。
    expect(fetchMock).toHaveBeenCalledTimes(3)
    expect(fetchMock.mock.calls[0][0]).toBe("/api/auth/access-token")
    expect(fetchMock.mock.calls[1][0]).toBe("/api/one")
    expect(fetchMock.mock.calls[2][0]).toBe("/api/two")
  })

  it("returns metadata from JWT payload", async () => {
    // 画面表示用メタデータとして iss/aud/exp を取り出せることを確認します。
    // aud が配列の場合に `api, web` へ整形される仕様も同時に確認します。
    vi.resetModules()
    const jwt = createJwt({
      iss: "https://issuer.example.com",
      aud: ["api", "web"],
      exp: 1_800_000_000,
    })

    const fetchMock = vi.fn().mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          accessToken: jwt,
          expiresAt: 1_700_000_100,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
    )
    vi.stubGlobal("fetch", fetchMock)

    const { getApiTokenMetadata } = await import("@/lib/auth/api-fetch")
    const metadata = await getApiTokenMetadata()

    expect(metadata).toEqual({
      issuer: "https://issuer.example.com",
      audience: "api, web",
      expiresAt: 1_800_000_000,
    })
  })

  it("falls back to token expiresAt when JWT payload is invalid", async () => {
    // JWT 解析に失敗しても null で落とさず、最低限 expiresAt は返す仕様を確認します。
    // UI の期限表示が完全に失われないようにするための回復動作です。
    vi.resetModules()
    const fetchMock = vi.fn().mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          accessToken: "invalid-token",
          expiresAt: 1_700_000_100,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
    )
    vi.stubGlobal("fetch", fetchMock)

    const { getApiTokenMetadata } = await import("@/lib/auth/api-fetch")
    const metadata = await getApiTokenMetadata()

    expect(metadata).toEqual({
      expiresAt: 1_700_000_100,
    })
  })
})
