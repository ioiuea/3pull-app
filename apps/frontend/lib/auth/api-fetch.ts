"use client";

/**
 * API 呼び出し結果の共通型。
 *
 * - `ok: true`  のときは `data` にレスポンス内容が入る
 * - `ok: false` のときは `error` に失敗理由が入る
 */
export type ApiResult<T> =
  | { ok: true; status: number; data: T }
  | { ok: false; status: number; error: string };

/**
 * ブラウザメモリ上のアクセストークンキャッシュ。
 *
 * 注意:
 * - ページリロードで消える（永続化しない）
 * - タブごとに独立する
 */
type TokenCache = {
  accessToken: string | null;
  expiresAt: number | null;
};

/**
 * API 用 JWT から画面表示に使う主要クレーム。
 */
export type ApiTokenMetadata = {
  issuer?: string;
  audience?: string;
  expiresAt?: number;
};

/** JWT を取得するフロントエンド API エンドポイント。 */
const ACCESS_TOKEN_ENDPOINT = "/api/auth/access-token";

const tokenCache: TokenCache = {
  accessToken: null,
  expiresAt: null,
};

/**
 * セッションCookieを使って API 用 JWT を取得する。
 *
 * 優先順位:
 * 1. 期限内のキャッシュがあれば再利用
 * 2. なければ `/api/auth/access-token` へ問い合わせ
 *
 * @returns トークン情報（未認証時は `null`）
 */
async function getAccessToken(): Promise<{
  accessToken: string;
  expiresAt: number;
} | null> {
  const now = Math.floor(Date.now() / 1000);

  if (
    tokenCache.accessToken &&
    tokenCache.expiresAt &&
    tokenCache.expiresAt > now + 5
  ) {
    return {
      accessToken: tokenCache.accessToken,
      expiresAt: tokenCache.expiresAt,
    };
  }

  const response = await fetch(ACCESS_TOKEN_ENDPOINT, {
    method: "GET",
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
    },
    cache: "no-store",
  });

  if (!response.ok) {
    // 未認証などは例外にせず null を返し、呼び出し側で扱えるようにする。
    return null;
  }

  const body = (await response.json()) as {
    accessToken: string;
    expiresAt: number;
  };

  tokenCache.accessToken = body.accessToken;
  tokenCache.expiresAt = body.expiresAt;

  return body;
}

const parseJwtPayload = (token: string): Record<string, unknown> | null => {
  const parts = token.split(".");
  if (parts.length !== 3) {
    return null;
  }

  const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
  const normalized = base64.padEnd(Math.ceil(base64.length / 4) * 4, "=");

  try {
    const decoded = atob(normalized);
    return JSON.parse(decoded) as Record<string, unknown>;
  } catch {
    return null;
  }
};

/**
 * 現在の API 用 JWT から `iss` / `aud` / `exp` を取得する。
 *
 * 画面表示向けの補助情報であり、認証判定には利用しない。
 *
 * @returns 取得できたトークンメタ情報（未認証時は `null`）
 */
export async function getApiTokenMetadata(): Promise<ApiTokenMetadata | null> {
  const tokenInfo = await getAccessToken();
  if (!tokenInfo) {
    return null;
  }

  const payload = parseJwtPayload(tokenInfo.accessToken);
  if (!payload) {
    return {
      expiresAt: tokenInfo.expiresAt,
    };
  }

  const aud = payload.aud;
  return {
    issuer: typeof payload.iss === "string" ? payload.iss : undefined,
    audience:
      typeof aud === "string"
        ? aud
        : Array.isArray(aud)
          ? aud
              .filter((item): item is string => typeof item === "string")
              .join(", ")
          : undefined,
    expiresAt:
      typeof payload.exp === "number" ? payload.exp : tokenInfo.expiresAt,
  };
}

/**
 * `Authorization: Bearer <token>` を自動付与して `fetch` するラッパー。
 *
 * 返却は例外ではなく `ApiResult<T>` で統一するため、
 * 呼び出し側で成功/失敗を分岐しやすい。
 *
 * @param input リクエスト先 URL
 * @param init fetch オプション
 * @returns 構造化された API 実行結果
 */
export async function fetchWithApiAuth<T = unknown>(
  input: string,
  init?: RequestInit,
): Promise<ApiResult<T>> {
  const tokenInfo = await getAccessToken();
  if (!tokenInfo) {
    return { ok: false, status: 401, error: "not_authenticated" };
  }

  const headers = new Headers(init?.headers);
  if (!headers.has("Content-Type") && !(init?.body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }
  headers.set("Authorization", `Bearer ${tokenInfo.accessToken}`);

  const response = await fetch(input, {
    ...init,
    headers,
  });

  const status = response.status;
  if (status === 204) {
    // No Content は成功扱いで data は null を返す。
    return { ok: true, status, data: null as unknown as T };
  }

  const text = await response.text();
  try {
    const data =
      text && text.length > 0 ? (JSON.parse(text) as T) : (null as T);
    if (!response.ok) {
      return {
        ok: false,
        status,
        error: typeof data === "string" ? data : JSON.stringify(data),
      };
    }
    return { ok: true, status, data };
  } catch {
    // JSON 以外のレスポンス（plain text等）にも対応する。
    if (!response.ok) {
      return { ok: false, status, error: text || response.statusText };
    }
    return { ok: true, status, data: text as unknown as T };
  }
}

/**
 * 認証ヘッダだけ付与して、生の `Response` を返すラッパー。
 *
 * ファイルダウンロードやストリームなど、
 * 呼び出し側で `Response` を直接扱いたい場合に利用する。
 *
 * @param input リクエスト先 URL
 * @param init fetch オプション
 * @returns 認証付き Response（未認証時は `null`）
 */
export async function fetchWithApiAuthRaw(
  input: string,
  init?: RequestInit,
): Promise<Response | null> {
  const tokenInfo = await getAccessToken();
  if (!tokenInfo) {
    return null;
  }

  const headers = new Headers(init?.headers);
  headers.set("Authorization", `Bearer ${tokenInfo.accessToken}`);

  return fetch(input, {
    ...init,
    headers,
  });
}
