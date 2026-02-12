import { NextResponse } from "next/server";

import { auth } from "@/lib/auth/server";

/**
 * `GET /api/auth/access-token`
 *
 * Better Auth セッション（Cookie）を検証し、
 * バックエンド API 用の短命 JWT を発行して返す。
 *
 * 想定フロー:
 * 1. `auth.api.getSession` で現在セッションを確認
 * 2. 未認証なら 401 を返す
 * 3. 認証済みなら `signApiToken` で JWT を署名
 * 4. `accessToken` と `expiresAt` を JSON 返却
 *
 * @param request Route Handler へ渡される HTTP リクエスト
 * @returns JWT を含む JSON レスポンス、または 401
 */
export async function GET(request: Request) {
  // Better Auth のセッションを Cookie から解決する。
  const session = await auth.api.getSession({
    headers: request.headers,
  });

  // セッションがない場合は未認証として終了。
  if (!session?.user?.id) {
    return NextResponse.json({ error: "not_authenticated" }, { status: 401 });
  }

  // 署名処理はサーバー専用モジュールに集約する。
  // Dynamic import にする理由:
  // - Route Handler 実行時にのみ読み込む（不要な初期読み込みを避ける）
  // - JWT 署名ロジックの責務をこのルート本体から分離して見通しを保つ
  const { signApiToken } = await import("@/server/sign-api-token");
  const activeOrganizationId = (
    session.session as { activeOrganizationId?: string } | undefined
  )?.activeOrganizationId;

  // API 用の短命JWT（既定5分）を発行する。
  const { signed, expiresAt } = await signApiToken(
    {
      sub: session.user.id,
      email: session.user.email,
      name: session.user.name,
      email_verified: session.user.emailVerified,
      active_organization_id: activeOrganizationId,
    },
    {
      expiresInSec: 60 * 5,
    },
  );

  // キャッシュさせない（常に最新セッション基準で発行する）。
  return NextResponse.json(
    { accessToken: signed, expiresAt },
    {
      headers: {
        "Cache-Control": "no-store",
      },
    },
  );
}
