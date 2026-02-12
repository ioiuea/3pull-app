import { SampleZustandClient } from "@/features/sample/zustand";
import { getDictionary } from "@/lib/i18n/dictionary";
import { type Locale } from "@/lib/i18n/locales";

type SampleZustandPageProps = {
  params: Promise<{ lang: Locale }>;
};

const SampleZustandPage = async ({ params }: SampleZustandPageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);

  return <SampleZustandClient dict={dict} lang={lang} />;
};

export default SampleZustandPage;
