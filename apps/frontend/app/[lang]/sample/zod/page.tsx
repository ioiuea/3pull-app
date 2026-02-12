import { SampleZodClient } from "@/features/sample/zod";
import { getDictionary } from "@/lib/i18n/dictionary";
import { type Locale } from "@/lib/i18n/locales";

type SampleZodPageProps = {
  params: Promise<{ lang: Locale }>;
};

const SampleZodPage = async ({ params }: SampleZodPageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);

  return <SampleZodClient dict={dict} lang={lang} />;
};

export default SampleZodPage;
