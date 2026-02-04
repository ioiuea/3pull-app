"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { DEFAULT_LOCALE, SUPPORTED_LOCALES, type Locale } from "@/lib/i18n";

const getNextPath = (pathname: string, nextLocale: Locale) => {
  const segments = pathname.split("/");
  const maybeLocale = segments[1] ?? "";
  const hasLocale = SUPPORTED_LOCALES.includes(maybeLocale as Locale);
  const rest = hasLocale ? segments.slice(2) : segments.slice(1);
  const suffix = rest.length > 0 ? `/${rest.join("/")}` : "";
  return `/${nextLocale}${suffix}`;
};

export function LocaleSwitcher() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const router = useRouter();

  const segments = pathname.split("/");
  const current = segments[1] ?? "";
  const activeLocale = SUPPORTED_LOCALES.includes(current as Locale)
    ? (current as Locale)
    : DEFAULT_LOCALE;

  const handleChangeLocale = (nextLocale: Locale) => {
    const nextPath = getNextPath(pathname, nextLocale);
    const query = searchParams.toString();
    router.push(query ? `${nextPath}?${query}` : nextPath);
  };

  return (
    <Select onValueChange={handleChangeLocale} value={activeLocale}>
      <SelectTrigger className="w-20">
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        {SUPPORTED_LOCALES.map((locale) => (
          <SelectItem key={locale} value={locale}>
            {locale.toUpperCase()}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}
