import Image from "next/image";
import { APP_NAME } from "@/const/app";
import { LoginClient } from "@/features/login";
import { getDictionary } from "@/lib/dictionaries";
import { type Locale } from "@/lib/i18n";

const LoginPage = async ({ params }: { params: Promise<{ lang: Locale }> }) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);

  return (
    <div className="flex min-h-svh flex-col items-center justify-center gap-6 bg-muted p-6 md:p-10">
      <div className="flex w-full max-w-sm flex-col gap-6">
        <div className="flex items-center gap-2 self-center font-medium">
          <div className="flex size-6 items-center justify-center rounded-md bg-primary text-primary-foreground">
            <Image
              alt="Product Logo"
              height={50}
              priority
              src={"/3pull.png"}
              width={50}
            />
          </div>
          {APP_NAME}
        </div>
        <LoginClient dict={dict} />
      </div>
    </div>
  );
};

export default LoginPage;
