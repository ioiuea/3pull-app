import Image from "next/image";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { APP_NAME } from "@/const/app";
import { getDictionary } from "@/lib/dictionaries";
import { type Locale } from "@/lib/i18n";

const HomePage = async ({ params }: { params: Promise<{ lang: Locale }> }) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);
  const { home } = dict;

  return (
    <>
      <div className="flex h-screen flex-col items-center justify-center gap-5 px-5 text-center">
        <Image
          alt="Product Logo"
          className="rounded-lg dark:invert"
          height={100}
          src="/3pull.png"
          width={100}
        />

        <h1 className="font-bold text-4xl">{APP_NAME}</h1>

        <p className="text-lg">{home.description}</p>

        <div className="flex flex-wrap items-center justify-center gap-3">
          <Button asChild>
            <Link href={`/${lang}/organizations`}>Organizations</Link>
          </Button>
          <Button asChild variant="outline">
            <Link href={`/${lang}/sample`}>Sample</Link>
          </Button>
        </div>
      </div>
    </>
  );
};

export default HomePage;
