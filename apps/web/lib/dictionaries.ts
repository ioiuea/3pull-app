import "server-only";
import { DEFAULT_LOCALE, SUPPORTED_LOCALES, type Locale } from "@/lib/i18n";

/**
 * 利用可能な辞書ローダー。
 * - キーがロケール
 * - 値が辞書(JSON)を動的に読み込む関数
 */
const dictionaries = {
  en: () => import("@/dictionaries/en.json").then((module) => module.default),
  ja: () => import("@/dictionaries/ja.json").then((module) => module.default),
} as const;

export type { Locale } from "@/lib/i18n";
export { DEFAULT_LOCALE, SUPPORTED_LOCALES } from "@/lib/i18n";

/**
 * 指定ロケールの辞書を取得する。
 * @param locale - サポートされるロケール
 * @returns 対応する辞書データ
 */
export const getDictionary = async (locale: Locale) =>
  dictionaries[locale]();

/**
 * 文字列がサポートロケールかを判定する。
 * @param value - 判定対象の文字列
 * @returns サポートロケールなら true
 */
const isSupportedLocale = (value?: string): value is Locale =>
  value !== undefined && SUPPORTED_LOCALES.includes(value as Locale);

/**
 * cookie 等から得た候補ロケールを正規化する補助ヘルパー。
 * - localeCookie が有効ならそれを優先
 * - 未指定/未対応なら DEFAULT_LOCALE
 * @param localeCookie - cookie 等から得た候補ロケール
 * @returns 正規化済みロケール
 */
export async function getLang(localeCookie?: string): Promise<Locale> {
  if (isSupportedLocale(localeCookie)) {
    return localeCookie;
  }

  return DEFAULT_LOCALE;
}
