"use server";

import { SignJWT, importPKCS8 } from "jose";

/**
 * API JWT に含めるアプリケーション固有クレーム。
 *
 * `sub` は必須（ユーザーID）。
 * それ以外は必要なときだけ付与する。
 */
export type ApiTokenClaims = {
  sub: string;
  email?: string;
  name?: string;
  email_verified?: boolean;
  active_organization_id?: string;
  organization_role?: string;
};

/**
 * JWT 発行時のオプション。
 */
export type SignApiTokenOptions = {
  /**
   * トークン有効秒数。
   * 未指定時は 5 分。
   */
  expiresInSec?: number;
};

/**
 * 必須環境変数を取得する。
 *
 * 値が未設定または空文字の場合は例外を投げ、
 * 実行時に設定漏れへ早く気付けるようにする。
 */
const getRequiredEnv = (name: string): string => {
  const value = process.env[name];
  if (!value || !value.trim()) {
    throw new Error(`${name} is not set`);
  }
  return value;
};

/**
 * `.env` で `\n` エスケープされた PEM を実改行へ戻す。
 *
 * 例:
 * `-----BEGIN...\\nABC...\\n-----END...` -> 実際の改行を含むPEM文字列
 */
const normalizePem = (value: string): string => value.replace(/\\n/g, "\n").trim();

/**
 * Better Auth セッションで同定したユーザー情報をもとに、
 * バックエンド API 用の短命 JWT (RS256) を発行する。
 *
 * 処理の流れ:
 * 1. 署名鍵（JWT_PRIVATE_KEY）を読み込む
 * 2. 期限・issuer・audience を決める
 * 3. 必要クレームで JWT を署名
 * 4. トークン本体と期限Unix秒を返す
 *
 * @param claims JWTに埋め込むクレーム
 * @param options 発行オプション（期限など）
 * @returns 署名済みJWT文字列と期限
 */
export const signApiToken = async (
  claims: ApiTokenClaims,
  options: SignApiTokenOptions = {},
): Promise<{ signed: string; expiresAt: number }> => {
  const privateKeyPem = normalizePem(getRequiredEnv("JWT_PRIVATE_KEY"));
  const issuer = process.env.JWT_ISSUER ?? "3pull-web";
  const audience = process.env.JWT_AUDIENCE ?? "3pull-api";
  const expiresInSec = options.expiresInSec ?? 60 * 5;

  const now = Math.floor(Date.now() / 1000);
  const expiresAt = now + expiresInSec;

  const key = await importPKCS8(privateKeyPem, "RS256");

  const payload = {
    email: claims.email,
    name: claims.name,
    email_verified: claims.email_verified,
    active_organization_id: claims.active_organization_id,
    organization_role: claims.organization_role,
  };

  const signed = await new SignJWT(payload)
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setSubject(claims.sub)
    .setIssuer(issuer)
    .setAudience(audience)
    .setIssuedAt(now)
    .setExpirationTime(expiresAt)
    .sign(key);

  return { signed, expiresAt };
};
