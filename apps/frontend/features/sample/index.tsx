"use client";

import Link from "next/link";
import { motion } from "motion/react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { type Locale } from "@/lib/i18n/locales";

type Dictionary = typeof import("@/dictionaries/en.json");

type SampleClientProps = {
  dict: Dictionary;
  lang: Locale;
};

export const SampleClient = ({ dict, lang }: SampleClientProps) => {
  const { sample } = dict;

  return (
    <div className="min-h-screen bg-linear-to-br from-background via-muted/40 to-muted/70 px-6 py-12 text-foreground">
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="mx-auto flex w-full max-w-5xl flex-col gap-8"
      >
        <Card className="border-0 bg-transparent shadow-none">
          <CardHeader className="px-0 pb-4">
            <div className="flex items-center gap-3">
              <Badge variant="secondary">{sample.index.badge}</Badge>
              <Badge variant="outline">Zustand</Badge>
              <Badge variant="outline">Zod</Badge>
              <Badge variant="outline">SWR</Badge>
            </div>
            <CardTitle className="text-4xl font-semibold tracking-tight">
              {sample.index.title}
            </CardTitle>
            <CardDescription className="text-base leading-7">
              {sample.index.description}
            </CardDescription>
          </CardHeader>
          <Separator />
        </Card>

        <motion.section
          initial="hidden"
          animate="show"
          variants={{
            hidden: { opacity: 0 },
            show: { opacity: 1, transition: { staggerChildren: 0.12 } },
          }}
          className="grid gap-6 lg:grid-cols-3"
        >
          {[
            {
              key: "zustand",
              href: `/${lang}/sample/zustand`,
              data: sample.index.cards.zustand,
            },
            {
              key: "zod",
              href: `/${lang}/sample/zod`,
              data: sample.index.cards.zod,
            },
            {
              key: "swr",
              href: `/${lang}/sample/swr`,
              data: sample.index.cards.swr,
            },
          ].map((card) => (
            <motion.div
              key={card.key}
              variants={{
                hidden: { opacity: 0, y: 16 },
                show: { opacity: 1, y: 0 },
              }}
            >
              <Card className="h-full">
                <CardHeader>
                  <CardTitle>{card.data.title}</CardTitle>
                  <CardDescription>{card.data.description}</CardDescription>
                </CardHeader>
                <CardContent>
                  <Button asChild className="w-full">
                    <Link href={card.href}>{card.data.cta}</Link>
                  </Button>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </motion.section>

        <div>
          <Button asChild variant="ghost">
            <Link href={`/${lang}`}>{sample.index.backToHome}</Link>
          </Button>
        </div>
      </motion.div>
    </div>
  );
};
