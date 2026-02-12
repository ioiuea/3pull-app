import { HealthClient } from "@/features/health";
import { getDictionary } from "@/lib/i18n/dictionary";
import { type Locale } from "@/lib/i18n/locales";

type HealthPageProps = {
  params: Promise<{ lang: Locale }>;
};

const HealthPage = async ({ params }: HealthPageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);

  return <HealthClient dict={dict} lang={lang} />;
};

export default HealthPage;
