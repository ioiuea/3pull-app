import Image from "next/image";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { getDictionary, type Locale } from "@/lib/dictionaries";

const appName = process.env.NEXT_PUBLIC_APP_NAME ?? "3pull";

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

        <h1 className="font-bold text-4xl">{appName}</h1>

        <p className="text-lg">{home.description}</p>

        <Link href="/login">
          <Button>Login</Button>
        </Link>
      </div>
    </>
  );
};

export default HomePage;
