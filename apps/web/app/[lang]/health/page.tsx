import { HealthClient } from "@/features/health";
import { getDictionary } from "@/lib/dictionaries";
import { type Locale } from "@/lib/i18n";

type HealthPageProps = {
  params: Promise<{ lang: Locale }>;
};

const HealthPage = async ({ params }: HealthPageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);

  return <HealthClient dict={dict} lang={lang} />;
};

export default HealthPage;
