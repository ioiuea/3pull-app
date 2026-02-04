import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { cookies } from "next/headers";
import { LocaleSwitcher } from "@/components/locale-switcher";
import { ModeSwitcher } from "@/components/mode-switcher";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import { getLang } from "@/lib/dictionaries";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const appName = process.env.NEXT_PUBLIC_APP_NAME ?? "3pull";
const appDescription =
  process.env.NEXT_PUBLIC_APP_DESCRIPTION ?? "Simple starter";

export const metadata: Metadata = {
  title: appName,
  description: appDescription,
};

const RootLayout = async ({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) => {
  const localeCookie = (await cookies()).get("locale")?.value;
  const lang = await getLang(localeCookie);

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
