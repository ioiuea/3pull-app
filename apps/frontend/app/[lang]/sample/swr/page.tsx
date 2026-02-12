import { SampleSwrClient } from "@/features/sample/swr";
import { getDictionary } from "@/lib/i18n/dictionary";
import { type Locale } from "@/lib/i18n/locales";

type SampleSwrPageProps = {
  params: Promise<{ lang: Locale }>;
};

const SampleSwrPage = async ({ params }: SampleSwrPageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);

  return <SampleSwrClient dict={dict} lang={lang} />;
};

export default SampleSwrPage;
