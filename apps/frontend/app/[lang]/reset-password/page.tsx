import Image from "next/image";
import Link from "next/link";
import { Suspense } from "react";
import { APP_NAME } from "@/const/app";
import { ResetPasswordClient } from "@/features/reset-password";
import { getDictionary } from "@/lib/i18n/dictionary";
import { type Locale } from "@/lib/i18n/locales";

const ResetPasswordPage = async ({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);

  return (
    <div className="flex min-h-svh flex-col items-center justify-center gap-6 bg-muted p-6 md:p-10">
      <div className="flex w-full max-w-sm flex-col gap-6">
        <Link
          className="flex items-center gap-2 self-center font-medium"
          href="/"
        >
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
        </Link>
        <Suspense
          fallback={<div className="text-center text-sm">Loading…</div>}
        >
          <ResetPasswordClient dict={dict} />
        </Suspense>
      </div>
    </div>
  );
};

export default ResetPasswordPage;
