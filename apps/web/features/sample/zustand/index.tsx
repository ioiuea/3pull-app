"use client";

import Link from "next/link";
import { useEffect } from "react";
import { motion } from "motion/react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { type Locale } from "@/lib/i18n";
import useSampleStore from "@/store/sampleStore";

type Dictionary = typeof import("@/dictionaries/en.json");

type SampleZustandClientProps = {
  dict: Dictionary;
  lang: Locale;
};

export const SampleZustandClient = ({
  dict,
  lang,
}: SampleZustandClientProps) => {
  const { sample } = dict;
  const { count, label, setLabel, increment, decrement, reset } =
    useSampleStore();

  useEffect(() => {
    setLabel(sample.zustand.labelDefault);
  }, [sample.zustand.labelDefault, setLabel]);

  return (
    <div className="min-h-screen bg-linear-to-br from-background via-muted/40 to-muted/70 px-6 py-12 text-foreground">
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="mx-auto flex w-full max-w-3xl flex-col gap-8"
      >
        <div>
          <Button asChild variant="ghost">
            <Link href={`/${lang}/sample`}>{sample.backToSamples}</Link>
          </Button>
        </div>

        <Card className="border-0 bg-transparent shadow-none">
          <CardHeader className="px-0 pb-4">
            <div className="flex items-center gap-3">
              <Badge variant="secondary">{sample.index.badge}</Badge>
              <Badge variant="outline">{sample.zustand.badge}</Badge>
            </div>
            <CardTitle className="text-4xl font-semibold tracking-tight">
              {sample.zustand.title}
            </CardTitle>
            <p className="text-base leading-7 text-muted-foreground">
              {sample.zustand.description}
            </p>
          </CardHeader>
        </Card>

        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          <Card>
            <CardHeader className="flex flex-row items-start justify-between gap-4">
              <div>
                <CardTitle>{sample.zustand.counterTitle}</CardTitle>
                <p className="text-sm text-muted-foreground">
                  {sample.zustand.counterDescription}
                </p>
              </div>
              <Badge>{label}</Badge>
            </CardHeader>
            <CardContent className="space-y-4">
              <motion.p
                key={count}
                initial={{ scale: 0.9, opacity: 0.6 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.25 }}
                className="text-4xl font-semibold"
              >
                {count}
              </motion.p>
              <div className="flex flex-wrap gap-2">
                <Button type="button" onClick={increment}>
                  {sample.zustand.incrementCta}
                </Button>
                <Button type="button" variant="secondary" onClick={decrement}>
                  {sample.zustand.decrementCta}
                </Button>
                <Button type="button" variant="outline" onClick={reset}>
                  {sample.zustand.resetCta}
                </Button>
              </div>
              <div className="space-y-2">
                <Label htmlFor="label-input">
                  {sample.zustand.labelFieldLabel}
                </Label>
                <Input
                  id="label-input"
                  placeholder={sample.zustand.labelPlaceholder}
                  value={label}
                  onChange={(event) => setLabel(event.target.value)}
                />
              </div>
            </CardContent>
          </Card>
        </motion.section>
      </motion.div>
    </div>
  );
};
