import { type Locale } from "@/lib/i18n/locales";
import { getDictionary } from "@/lib/i18n/dictionary";

type TermsPageProps = {
  params: Promise<{ lang: Locale }>;
};

const TermsPage = async ({ params }: TermsPageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);
  const { terms } = dict;

  return (
    <main className="container mx-auto max-w-2xl space-y-6 px-6 py-10">
      <div>
        <a className="text-sm underline underline-offset-4" href={`/${lang}`}>
          Home
        </a>
      </div>
      <header className="space-y-2">
        <h1 className="text-3xl font-semibold tracking-tight">{terms.title}</h1>
        <p className="text-sm text-muted-foreground">
          {terms.lastUpdatedLabel}: {terms.lastUpdatedValue}
        </p>
      </header>
      <section className="space-y-4 text-sm text-muted-foreground">
        <p>{terms.intro}</p>
        <p>{terms.body}</p>
      </section>
    </main>
  );
};

export default TermsPage;
