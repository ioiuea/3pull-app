import { SampleSwrClient } from "@/features/sample/swr";
import { getDictionary } from "@/lib/dictionaries";
import { type Locale } from "@/lib/i18n";

type SampleSwrPageProps = {
  params: Promise<{ lang: Locale }>;
};

const SampleSwrPage = async ({ params }: SampleSwrPageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);

  return <SampleSwrClient dict={dict} lang={lang} />;
};

export default SampleSwrPage;
