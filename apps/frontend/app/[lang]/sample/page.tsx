import { SampleClient } from "@/features/sample";
import { getDictionary } from "@/lib/dictionaries";
import { type Locale } from "@/lib/i18n";

type SamplePageProps = {
  params: Promise<{ lang: Locale }>;
};

const SamplePage = async ({ params }: SamplePageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);

  return <SampleClient dict={dict} lang={lang} />;
};

export default SamplePage;
