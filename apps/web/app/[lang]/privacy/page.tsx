import { type Locale } from "@/lib/i18n";
import { getDictionary } from "@/lib/dictionaries";

type PrivacyPageProps = {
  params: Promise<{ lang: Locale }>;
};

const PrivacyPage = async ({ params }: PrivacyPageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);
  const { legal } = dict;

  return (
    <main className="container mx-auto max-w-2xl space-y-6 px-6 py-10">
      <div>
        <a className="text-sm underline underline-offset-4" href={`/${lang}`}>
          Home
        </a>
      </div>
      <header className="space-y-2">
        <h1 className="text-3xl font-semibold tracking-tight">
          {legal.privacyTitle}
        </h1>
        <p className="text-sm text-muted-foreground">
          {legal.lastUpdatedLabel}: {legal.lastUpdatedValue}
        </p>
      </header>
      <section className="space-y-4 text-sm text-muted-foreground">
        <p>{legal.privacyIntro}</p>
        <p>{legal.privacyBody}</p>
      </section>
    </main>
  );
};

export default PrivacyPage;
