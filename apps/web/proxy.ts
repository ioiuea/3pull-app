import { getSessionCookie } from "better-auth/cookies";
import { type NextRequest, NextResponse } from "next/server";
import { match as matchLocale } from "@formatjs/intl-localematcher";
import Negotiator from "negotiator";
import { PUBLIC_PATHS } from "@/const/public-routes";
import { DEFAULT_LOCALE, SUPPORTED_LOCALES } from "@/lib/i18n";

const LOCALE_COOKIE = "locale";

/**
 * 判定: URL パスにロケール (言語コード) プレフィックスが付いているかを判定します。
 *
 * @remarks
 * サポートされるロケール（`SUPPORTED_LOCALES`）のいずれかで始まっている場合に true を返します。
 * 例えば `/ja` または `/en/dashboard` のようなパスが対象です。
 *
 * i18n対応サイトでは、ロケールが指定されていないリクエストを検出し、
 * `detectLocale` による言語推定を行う前段階のフィルタとして利用します。
 *
 * @param pathname - 判定対象の URL パス（例: `/en/about`）
 * @returns ロケールプレフィックスを含む場合は true、それ以外は false。
 *
 * @example
 * ```ts
 * hasLocalePrefix("/ja") // true
 * hasLocalePrefix("/en/dashboard") // true
 * hasLocalePrefix("/dashboard") // false
 * ```
 */
function hasLocalePrefix(pathname: string): boolean {
  return SUPPORTED_LOCALES.some(
    (l) => pathname === `/${l}` || pathname.startsWith(`/${l}/`),
  );
}

/**
 * 検出: ブラウザの言語設定から最適なロケールを推定します。
 *
 * @remarks
 * `Accept-Language` ヘッダーを解析して、サポート対象 (`SUPPORTED_LOCALES`) の中から
 * 最も適したロケールを返します。対応しない場合は `DEFAULT_LOCALE` を返します。
 *
 * 内部では `Negotiator` と `@formatjs/intl-localematcher` を使用して、
 * 国別タグや優先度の高いロケールを正確に選定します。
 *
 * @param req - Next.js の `NextRequest` オブジェクト。
 * @returns 推定されたロケール文字列（例: `"ja"` または `"en"`）
 *
 * @example
 * ```ts
 * const locale = detectLocale(req);
 * // => ブラウザが "ja,en;q=0.9" の場合、"ja" が返る
 * ```
 */
function detectLocale(req: NextRequest): string {
  const headers: Record<string, string> = {
    "accept-language": req.headers.get("accept-language") ?? "",
  };
  const languages = new Negotiator({ headers }).languages();
  return matchLocale(
    languages,
    SUPPORTED_LOCALES as unknown as string[],
    DEFAULT_LOCALE,
  );
}

/**
 * 判定: 認証不要（公開）パスかどうかを判別します。
 *
 * @remarks
 * middleware 内で認可判定を行う前に呼び出され、
 * 次のような「誰でもアクセス可能なルート」を true として返します。
 *
 * - `/signin` または `/signin/*` : カスタムサインインページ
 *
 * 上記に該当しないパスは保護対象（認証必須）とみなされます。
 *
 * @param pathname - 現在リクエスト中の URL パス（例: `/ja/dashboard`）
 * @returns 公開パスなら true、保護パスなら false を返します。
 *
 * @example
 * ```ts
 * isPublic("/login");          // true
 * isPublic("/ja/login");       // true
 * isPublic("/ja/dashboard");    // false
 * ```
 */
function isPublic(pathname: string): boolean {
  // ロケールプレフィックス（/ja や /en）を取り除き、常に「実際のページパス」に揃える。
  const normalizedPath = SUPPORTED_LOCALES.reduce((current, locale) => {
    if (current === `/${locale}`) {
      return "/";
    }
    if (current.startsWith(`/${locale}/`)) {
      return current.slice(locale.length + 1);
    }
    return current;
  }, pathname);

  return PUBLIC_PATHS.some((path) => {
    if (path === "/") {
      return normalizedPath === "/";
    }
    return normalizedPath === path || normalizedPath.startsWith(`${path}/`);
  });
}

/**
 * Edge Middleware 本体。
 *
 * @remarks
 * この関数はすべてのリクエストの前段で実行されます。
 *
 * 主な責務は次の 2 つです：
 *
 * 1. **i18n ロケール付与**
 *    - リクエストパスにロケールプレフィックス（例: `/ja`）が含まれない場合、
 *      ブラウザの `Accept-Language` から適切なロケールを推定し、
 *      そのロケールを付加してリダイレクトします。
 *
 * 2. **認可チェック（Edge 互換版）**
 *    - 公開ルート（`isPublic()`）以外のアクセスでは、`getToken()` を使用して
 *      有効な JWT セッションが存在するかを確認します。
 *    - トークンが存在しない場合は、対象ロケールの `/signin` ページへ
 *      リダイレクトし、`callbackUrl` に元のパスを付与します。
 *
 * Prisma など Node.js 専用モジュールは Edge Runtime で動作しないため、
 * 認可処理には Auth.js の `getToken` を利用して JWT のみで判定します。
 *
 * @param req - Next.js の {@link NextRequest} オブジェクト。
 * @returns {@link NextResponse} オブジェクト。
 */
export async function proxy(req: NextRequest) {
  const sessionCookie = await getSessionCookie(req);

  const { pathname } = req.nextUrl;

  const locale = detectLocale(req);
  const urlLocale = hasLocalePrefix(pathname) ? pathname.split("/")[1] : null;

  // --- 1) i18n: ロケール付与（例: /foo → /ja/foo） ---
  if (!hasLocalePrefix(pathname)) {
    const url = req.nextUrl.clone();
    url.pathname = `/${locale}${pathname}`;

    const response = NextResponse.redirect(url);
    response.cookies.set(LOCALE_COOKIE, locale, { path: "/" });
    return response;
  }

  // --- 2) 認可: 公開パス以外は sessionCookie で判定 ---
  if (!isPublic(pathname)) {
    if (!sessionCookie) {
      return NextResponse.redirect(new URL(`/${locale}`, req.url));
    }
  }

  const response = NextResponse.next();
  if (urlLocale && SUPPORTED_LOCALES.includes(urlLocale as never)) {
    response.cookies.set(LOCALE_COOKIE, urlLocale, { path: "/" });
  }
  return response;
}

/**
 * Next.js Middleware の適用範囲設定。
 *
 * @remarks
 * - `/api` は **全て除外**（認証・権限制御は各 Route Handler / API 内で実施する方針）
 * - `/_next` は **配下すべて除外**（内部アセット・HMR・画像最適化などをまとめて対象外）
 * - 静的アセットは **拡張子で一括除外**（ico/xml などの重複定義も整理）
 */
export const config = {
  matcher: [
    "/((?!api/|_next/|backend(?:/|$)|.*\\.(?:js|css|png|jpg|jpeg|svg|ico|gif|webp|avif|map|txt|xml|json|woff2?|ttf)$).*)",
  ],
};
