import "server-only";

const dictionaries = {
  en: () => import("@/dictionaries/en.json").then((module) => module.default),
  ja: () => import("@/dictionaries/ja.json").then((module) => module.default),
} as const;

export type Locale = keyof typeof dictionaries;

export const SUPPORTED_LOCALES = Object.keys(dictionaries) as Locale[];
export const DEFAULT_LOCALE: Locale = "en";

export const getDictionary = async (locale: Locale) =>
  dictionaries[locale]();
