import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { cookies, headers } from "next/headers";
import { Logout } from "@/components/sample-switcher/logout";
import { LocaleSwitcher } from "@/components/sample-switcher/locale-switcher";
import { ModeSwitcher } from "@/components/sample-switcher/mode-switcher";
import { OrganizationSwitcher } from "@/components/sample-switcher/organization-switcher";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import { APP_DESCRIPTION, APP_NAME } from "@/const/app";
import { auth } from "@/lib/auth";
import { getLang } from "@/lib/dictionaries";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: APP_NAME,
  description: APP_DESCRIPTION,
  robots:
    process.env.BLOCK_SEARCH_INDEXING === "true"
      ? {
          index: false,
          follow: false,
          nocache: true,
          googleBot: {
            index: false,
            follow: false,
            noimageindex: true,
          },
        }
      : undefined,
};

const RootLayout = async ({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) => {
  const localeCookie = (await cookies()).get("locale")?.value;
  const lang = await getLang(localeCookie);
  const session = await auth.api.getSession({ headers: await headers() });

  return (
    <html lang={lang} suppressHydrationWarning>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          disableTransitionOnChange
          enableSystem
        >
          <div className="pointer-events-none fixed top-4 right-4 z-50">
            <div className="pointer-events-auto flex items-center gap-2 rounded-md border bg-background/80 p-1 shadow-sm backdrop-blur">
              <LocaleSwitcher />
              {session && <Logout />}
              {session && <OrganizationSwitcher />}
              <ModeSwitcher />
            </div>
          </div>
          {children}
          <Toaster richColors position="bottom-right" />
        </ThemeProvider>
      </body>
    </html>
  );
};

export default RootLayout;
